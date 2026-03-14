---
name: gitlab-issue
description: Interact with a GitLab issue — view, comment, update labels/assignee, start work, or finish and open an MR. Usage: /gitlab-issue <id-or-url> [action] where action is one of: view, comment, start, finish, move.
---

# GitLab Issue Command

Arguments: $ARGUMENTS

## Step 1: Parse

- **Issue ref**: bare ID (`42`) or full URL (`https://gitlab.example.com/group/project/-/issues/42`)
- **Action**: `view` (default) | `comment` | `start` | `finish` | `move`
- **Extra context**: comment text, target label, etc.

If URL: project path = everything between host and `/-/`; ID = number after `/issues/`.

## Step 2: Resolve Project

```bash
PROJECT=$(bash ${CLAUDE_SKILL_DIR}/../skills/gitlab-workflow/scripts/resolve-project.sh)
```

If not found, ask: *"Which GitLab project? (e.g. `group/project` or paste the issue URL)"*

Offer to save: `echo '{ "url": "https://..." }' > .gitlab-workflow.json && echo ".gitlab-workflow.json" >> .gitignore`

## Step 3: Verify Auth (first run in session)

```bash
glab auth status  # confirm username matches expected account
```

## Step 4: Execute

### `view`
```bash
glab issue view <id> -R "$PROJECT" --comments
```

### `comment`
Ask for text if not provided. Write in **first person as the user** — never as Claude. Confirm before posting.
```bash
glab issue note <id> -R "$PROJECT" -m "<comment>"
```

### `start`
```bash
glab issue view <id> -R "$PROJECT"
# get username from: glab auth status
glab issue update <id> -R "$PROJECT" --label "in-progress" --unlabel "to-do" --assignee <username>
glab issue note <id> -R "$PROJECT" -m "Starting work on this."
git checkout -b feat/issue-<id>-<short-title>
```

### `finish`
```bash
git commit -m "feat: <description>

Closes #<id>"
# cross-project: "Closes group/project#<id>"
git push -u origin <current-branch>
glab mr create --fill --target-branch main
glab issue update <id> -R "$PROJECT" --label "review" --unlabel "in-progress"
glab issue note <id> -R "$PROJECT" -m "MR up for review: !<mr-number>"
```

### `move`
Ask for target state if not specified.
```bash
glab issue update <id> -R "$PROJECT" --label "<new>" --unlabel "<old>"
```

## Errors

- **glab not found**: `brew install glab`
- **Not authenticated**: `glab auth login`
- **Project not found**: verify with `glab repo view -R <project>`
- **Permission denied**: `glab auth status`
