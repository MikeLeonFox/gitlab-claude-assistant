---
name: gitlab-commit
description: Create a git commit with a proper conventional commit message that optionally references or closes a GitLab issue. Usage: /gitlab-commit [issue-id-or-url] [closes|relates] — all arguments are optional; omitting an issue produces a plain conventional commit with no issue footer.
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
Examples:
- `/gitlab-commit` — no issue anywhere → plain conventional commit, no footer
- `/gitlab-commit` — saved issue found → closes saved issue
- `/gitlab-commit 42` — explicit ID, closes
- `/gitlab-commit relates` — reads saved issue, reference only
- `/gitlab-commit 42 closes` — explicit ID, closes

If URL: extract project path and issue ID.

## Step 2: Resolve Host and Project

Skip this step if no issue was found in Step 1.

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null) || root="."
GITLAB_URL=$(jq -r '.url // empty' "$root/.gitlab-workflow.json" 2>/dev/null)
```

**If `GITLAB_URL` is set** (primary path — use it directly, always prefer this):
```bash
GITLAB_HOST=$(echo "$GITLAB_URL" | sed 's|https://||' | cut -d'/' -f1)
PROJECT=$(echo "$GITLAB_URL" | sed 's|https://[^/]*/||; s|/-/.*||')
export GITLAB_HOST
# Always use full cross-project form: Closes group/project#N
```

**If `GITLAB_URL` is absent** (fallback — derive from scripts + git remote):
```bash
GITLAB_HOST=$(bash ${CLAUDE_SKILL_DIR}/../skills/gitlab-workflow/scripts/resolve-host.sh)
export GITLAB_HOST
PROJECT=$(bash ${CLAUDE_SKILL_DIR}/../skills/gitlab-workflow/scripts/resolve-project.sh)
git remote get-url origin
# If PROJECT differs from the git remote path → use Closes group/project#N; otherwise Closes #N
```

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

**With issue — url present in config (always full form):**
```bash
git commit -m "<type>(<scope>): <description>

Closes <group/project>#<id>"
```

**With issue — no url in config, same project:**
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
- Reference only: `Related to #<id>` / `Related to <group/project>#<id>`

Use heredoc form to preserve newlines — `git commit -m $'...\n\nCloses #N'` or a real multi-line string. Confirm message with user if unsure. `Closes #N` only auto-closes on merge to the **default branch**.

GitLab will automatically cross-reference the issue in its timeline when the commit is pushed — no manual note needed.

**Cross-project caveat:** When the issue is in a different project (`Closes group/project#N`), the auto cross-reference only appears in the issue timeline if the pusher has at least Reporter access to that project. If it doesn't show up, post a manual note: `glab issue note <id> -R <project> -m "Referenced in commit <sha> on <repo>"`.

## Step 6: Offer Next Steps

- Push: `git push`
- Create MR: `glab mr create --fill`
- Finish issue: `/gitlab-issue <id> finish`
