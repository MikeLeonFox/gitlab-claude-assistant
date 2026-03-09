---
name: gitlab-issue
description: Interact with a GitLab issue — view, comment, update labels/assignee, start work, or finish and open an MR. Usage: /gitlab-issue <id-or-url> [action] where action is one of: view, comment, start, finish, move.
---

# GitLab Issue Command

Perform GitLab issue actions via the `glab` CLI.

## Instructions

The user invoked `/gitlab-issue` with arguments: $ARGUMENTS

### Step 1: Parse arguments

Extract from `$ARGUMENTS`:
- **Issue reference** — either a bare ID (`42`) or a full GitLab URL (`https://gitlab.example.com/group/project/-/issues/42`)
- **Action** — one of: `view`, `comment`, `start`, `finish`, `move` (default: `view`)
- **Extra context** — any additional text (comment wording, target label, etc.)

If a full URL is provided, parse it to extract:
- Project path: everything between the host and `/-/` (e.g. `group/subgroup/project`)
- Issue ID: the number after `/issues/`

### Step 2: Resolve the GitLab project

If the project was not in a URL, resolve it:

```bash
PROJECT=$(bash ${CLAUDE_PLUGIN_ROOT}/skills/gitlab-workflow/scripts/resolve-project.sh)
```

If the script exits with an error (no project found), ask the user:
> "Which GitLab project are these issues in? (e.g. `group/project` or paste the full issue URL)"

Offer to save the answer to `.gitlab-workflow` so it's remembered:
```bash
echo "issue_project=<group/project>" > .gitlab-workflow
echo ".gitlab-workflow" >> .gitignore
```

### Step 3: Verify auth identity (first run in session)

```bash
glab auth status
```

Confirm the account matches who the user expects to post as.

### Step 4: Execute the action

---

#### `view` (default)

```bash
glab issue view <id> -R "$PROJECT" --comments
```

---

#### `comment`

Ask the user for the comment text if not provided. Write it in **first person** as the user — never as Claude. Confirm before posting.

```bash
glab issue note <id> -R "$PROJECT" -m "<comment text>"
```

---

#### `start`

Signal that work is beginning on this issue:

1. View the issue:
   ```bash
   glab issue view <id> -R "$PROJECT"
   ```

2. Get the authenticated username:
   ```bash
   glab auth status
   ```

3. Transition labels and assign:
   ```bash
   glab issue update <id> -R "$PROJECT" --label "in-progress" --unlabel "to-do" --assignee <username>
   ```

4. Post a start comment in first person (confirm wording with user if not specified):
   ```bash
   glab issue note <id> -R "$PROJECT" -m "Starting work on this."
   ```

5. Suggest branch name and offer to create it:
   ```bash
   git checkout -b feat/issue-<id>-<short-title>
   ```

---

#### `finish`

Signal that work is done and open an MR:

1. Commit staged changes with a closing reference:
   ```bash
   git commit -m "$(cat <<'EOF'
   feat: <description>

   Closes #<id>
   EOF
   )"
   ```
   If the issue is in a different project:
   ```
   Closes group/project#<id>
   ```

2. Push:
   ```bash
   git push -u origin <current-branch>
   ```

3. Create MR:
   ```bash
   glab mr create --fill --target-branch main
   ```

4. Update issue labels:
   ```bash
   glab issue update <id> -R "$PROJECT" --label "review" --unlabel "in-progress"
   ```

5. Comment with MR reference — in first person, do not mention Claude:
   ```bash
   glab issue note <id> -R "$PROJECT" -m "MR up for review: !<mr-number>"
   ```

---

#### `move`

Transition the issue to a different workflow state. Ask the user for target state if not specified.

```bash
glab issue update <id> -R "$PROJECT" --label "<new-label>" --unlabel "<old-label>"
```

---

## Error Handling

- **glab not found**: `brew install glab`
- **Not authenticated**: `glab auth login`
- **Project not found**: re-confirm project path, check `-R` value with `glab repo view -R <project>`
- **Permission denied**: user may not have access to that project; check with `glab auth status`
