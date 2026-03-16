---
name: gitlab-commit
description: Create a git commit with a proper conventional commit message that references or closes a GitLab issue. Usage: /gitlab-commit [issue-id-or-url] [closes|relates] ["optional note message"] — issue ID is optional if a current issue is saved in .gitlab-workflow.json. The optional message is appended to the auto-posted issue note.
---

# GitLab Commit Command

Arguments: $ARGUMENTS

## Step 1: Parse

- **Issue ref** (optional): bare ID (`42`) or full URL — if omitted, read from `.gitlab-workflow.json`:
  ```bash
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root="."
  ISSUE_ID=$(jq -r '.issue // empty' "$root/.gitlab-workflow.json" 2>/dev/null)
  ```
  If still not found, ask the user.
- **Relation**: `closes` (default) or `relates`/`related`
- **Note message** (optional): any remaining text after the relation keyword — used as extra context in the issue note (e.g. what changed, what was discovered, what's next)

Examples:
- `/gitlab-commit` — reads saved issue, closes, note uses commit description only
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

```bash
git commit -m "<type>(<scope>): <description>

Closes #<id>"
```

Variations:
- Omit scope: `feat: description`
- Cross-project: `Closes group/project#<id>`
- Reference only: `Related to #<id>`

Use heredoc form to preserve newlines — `git commit -m $'...\n\nCloses #N'` or a real multi-line string. Confirm message with user if unsure. `Closes #N` only auto-closes on merge to the **default branch**.

## Step 6: Auto-Post Commit Note to Issue

After committing, post a note to the linked issue with the commit reference:

```bash
COMMIT_SHA=$(git rev-parse --short HEAD)
BRANCH=$(git branch --show-current)
glab issue note <id> -R "$PROJECT" -m "Committed \`$COMMIT_SHA\` on \`$BRANCH\`: <commit description>

<note message if provided>"
```

- If the user supplied a note message, append it on a new line after the commit description.
- If no message was supplied, omit the second line entirely.

This keeps the issue updated automatically — team members see commit progress directly in the issue timeline.

## Step 7: Offer Next Steps

- Push: `git push`
- Create MR: `glab mr create --fill`
- Finish issue: `/gitlab-issue <id> finish`
