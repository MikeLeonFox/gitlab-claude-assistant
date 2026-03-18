---
name: gitlab-issue
description: Interact with a GitLab issue — view, comment, update labels/assignee, start work, or finish and open an MR. Usage: /gitlab-issue <id-or-url> [action] where action is one of: view, comment, start, finish, move. Issue ID is optional if a current issue is saved in .gitlab-workflow.json.
---

# GitLab Issue Command

Arguments: $ARGUMENTS

## Step 1: Parse

- **Issue ref**: bare ID (`42`) or full URL (`https://gitlab.example.com/group/project/-/issues/42`)
- **Action**: `view` (default) | `comment` | `start` | `finish` | `move`
- **Extra context**: comment text, target label, etc.

If no issue ref is provided, read it from `.gitlab-workflow.json`:
```bash
root=$(git rev-parse --show-toplevel 2>/dev/null) || root="."
ISSUE_ID=$(jq -r '.issue // empty' "$root/.gitlab-workflow.json" 2>/dev/null)
```
If still not found, ask the user.

If URL: project path = everything between host and `/-/`; ID = number after `/issues/`.

## Step 2: Resolve Host and Project

```bash
GITLAB_HOST=$(bash ${CLAUDE_SKILL_DIR}/../skills/gitlab-workflow/scripts/resolve-host.sh)
export GITLAB_HOST
PROJECT=$(bash ${CLAUDE_SKILL_DIR}/../skills/gitlab-workflow/scripts/resolve-project.sh)
```

If not found, ask: *"Which GitLab project? (e.g. `group/project` or paste the issue URL)"*

Offer to save: `echo '{ "url": "https://..." }' > .gitlab-workflow.json && echo ".gitlab-workflow.json" >> .gitignore`

## Content Style

- Issue descriptions and notes: **2-3 sentences max** — plain language, no jargon, no markdown headers
- When displaying an issue, summarize the description for the user in 2-3 sentences if it is long
- Comments posted as first person (never "Claude:"). Confirm wording before posting.

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
# Check other issues on the board for label conventions before applying:
glab issue list -R "$PROJECT" --output=json | jq -r '.[].labels[]?' | sort -u
# get username from: glab auth status
glab issue update <id> -R "$PROJECT" --label "in-progress" --unlabel "to-do" --assignee <username>
glab issue note <id> -R "$PROJECT" -m "Starting work on this."
git checkout -b feat/issue-<id>-<short-title>
```

Apply labels consistent with what other issues use. If the board uses a `status::` scoped label (e.g. `status::in-progress`), use that instead of a plain label.

Then save the active issue to `.gitlab-workflow.json` so subsequent `/gitlab-commit` and `/gitlab-issue finish` calls don't need the ID:
```bash
root=$(git rev-parse --show-toplevel 2>/dev/null) || root="."
config="$root/.gitlab-workflow.json"
if [[ -f "$config" ]]; then
  jq --argjson id <id> '. + {"issue": $id}' "$config" > "$config.tmp" && mv "$config.tmp" "$config"
else
  echo "{\"issue\": <id>}" > "$config"
fi
grep -qxF '.gitlab-workflow.json' "$root/.gitignore" 2>/dev/null || echo ".gitlab-workflow.json" >> "$root/.gitignore"
```

Use `/gitlab-commit` when committing — it reads the saved issue and auto-posts commit notes back to it.

### `finish`
```bash
git commit -m "feat: <description>

Closes #<id>"
# cross-project: "Closes group/project#<id>"
git push -u origin <current-branch>
glab mr create --fill --target-branch main
# Check board label conventions before applying:
glab issue list -R "$PROJECT" --output=json | jq -r '.[].labels[]?' | sort -u
glab issue update <id> -R "$PROJECT" --label "review" --unlabel "in-progress"
glab issue note <id> -R "$PROJECT" -m "MR up for review: !<mr-number>"
```

Then clear the active issue from `.gitlab-workflow.json`:
```bash
root=$(git rev-parse --show-toplevel 2>/dev/null) || root="."
config="$root/.gitlab-workflow.json"
[[ -f "$config" ]] && jq 'del(.issue)' "$config" > "$config.tmp" && mv "$config.tmp" "$config"
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
