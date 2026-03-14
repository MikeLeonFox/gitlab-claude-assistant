---
name: gitlab-commit
description: Create a git commit with a proper conventional commit message that references or closes a GitLab issue. Usage: /gitlab-commit <issue-id-or-url> [closes|relates] — stages changes and commits with the correct format.
---

# GitLab Commit Command

Arguments: $ARGUMENTS

## Step 1: Parse

- **Issue ref**: bare ID (`42`) or full URL
- **Relation**: `closes` (default) or `relates`/`related`

If URL: extract project path and issue ID.

## Step 2: Resolve Cross-Project Reference

```bash
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

## Step 6: Offer Next Steps

- Push: `git push`
- Create MR: `glab mr create --fill`
- Comment: `glab issue note <id> -R <project> -m "Committed the fix. Opening MR shortly."`
