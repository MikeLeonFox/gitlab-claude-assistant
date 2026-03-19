---
name: gitlab-commit
description: Create a git commit with a proper conventional commit message that optionally references or closes a GitLab issue. Usage: /gitlab-commit [issue-id-or-url] [closes|relates] ["optional note message"] — all arguments are optional; omitting an issue produces a plain conventional commit with no issue footer.
---

# GitLab Commit Command

Arguments: $ARGUMENTS

## Step 1: Parse

- **Issue ref** (optional): bare ID (`42`) or full URL — if omitted, read from `.gitlab-workflow.json`:
  ```bash
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root="."
  ISSUE_ID=$(jq -r '.issue // empty' "$root/.gitlab-workflow.json" 2>/dev/null)
  ```
  If still not found, **proceed without an issue** — skip the issue footer and note steps entirely.
- **Relation**: `closes` (default) or `relates`/`related`
- **Note message** (optional): any remaining text after the relation keyword — used as extra context in the issue note (e.g. what changed, what was discovered, what's next)

Examples:
- `/gitlab-commit` — no issue anywhere → plain conventional commit, no footer
- `/gitlab-commit` — saved issue found → closes saved issue + auto-posts note
- `/gitlab-commit 42` — explicit ID, closes
- `/gitlab-commit relates "partial fix, null case only"` — reads saved issue, reference + custom note
- `/gitlab-commit 42 "refactored token logic before tackling the main fix"` — explicit ID + custom note

If URL: extract project path and issue ID.

## Step 2: Resolve Host and Project

```bash
GITLAB_HOST=$(bash ${CLAUDE_SKILL_DIR}/../skills/gitlab-workflow/scripts/resolve-host.sh)
export GITLAB_HOST
PROJECT=$(bash ${CLAUDE_SKILL_DIR}/../skills/gitlab-workflow/scripts/resolve-project.sh)
git remote get-url origin
```

If project differs from current repo remote → use `Closes group/project#42`; otherwise `Closes #42`.

Skip this step if no issue was found in Step 1.

## Step 3: Check Staged Changes

```bash
git status && git diff --cached --stat
```

If nothing staged, show unstaged diff and ask which files to stage.

## Step 4: Determine Commit Message

Infer from diff or ask:
- **Type**: `feat` / `fix` / `docs` / `style` / `refactor` / `test` / `chore`
- **Scope** (optional): affected component
- **Description**: imperative mood, lowercase, no period, ≤72 chars

## Step 5: Commit

**With issue:**
```bash
git commit -m "<type>(<scope>): <description>

Closes #<id>"
```

**Without issue** (no issue found in Step 1):
```bash
git commit -m "<type>(<scope>): <description>"
```

Variations:
- Omit scope: `feat: description`
- Cross-project: `Closes group/project#<id>`
- Reference only: `Related to #<id>`

Use heredoc form to preserve newlines — `git commit -m $'...\n\nCloses #N'` or a real multi-line string. Confirm message with user if unsure. `Closes #N` only auto-closes on merge to the **default branch**.

## Step 6: Auto-Post Commit Note to Issue

**Skip entirely if no issue was found in Step 1.**

Otherwise, post a note to the linked issue with the commit reference:

```bash
COMMIT_SHA=$(git rev-parse --short HEAD)
COMMIT_SHA_FULL=$(git rev-parse HEAD)
BRANCH=$(git branch --show-current)
COMMIT_URL="https://$GITLAB_HOST/$PROJECT/-/commit/$COMMIT_SHA_FULL"
glab issue note <id> -R "$PROJECT" -m "Committed [$COMMIT_SHA]($COMMIT_URL) on \`$BRANCH\`: <commit description>

<note message if provided>"
```

- Link format `[$COMMIT_SHA]($COMMIT_URL)` makes the commit clickable in the issue and causes GitLab to cross-reference the commit in the issue timeline when pushed.
- If the user supplied a note message, append it on a new line after the commit description.
- If no message was supplied, omit the second line entirely.

## Step 7: Offer Next Steps

- Push: `git push`
- Create MR: `glab mr create --fill`
- Finish issue: `/gitlab-issue <id> finish`
