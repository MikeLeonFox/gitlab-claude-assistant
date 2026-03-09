---
name: gitlab-commit
description: Create a git commit with a proper conventional commit message that references or closes a GitLab issue. Usage: /gitlab-commit <issue-id-or-url> [closes|relates] — stages changes and commits with the correct format.
---

# GitLab Commit Command

Create a conventionally-formatted git commit that references a GitLab issue.

## Instructions

The user invoked `/gitlab-commit` with arguments: $ARGUMENTS

### Step 1: Parse arguments

- **Issue reference** — bare ID (`42`) or full GitLab URL
- **Relation** — `closes` (default) or `relates`/`related`

If a full URL is provided, extract:
- Project path (for cross-project reference): `group/project`
- Issue ID: `42`

### Step 2: Resolve cross-project reference

If the issue is in a **different** repo than the current git project, use the full cross-project syntax in the commit footer instead of just `#42`:

```bash
PROJECT=$(bash ${CLAUDE_PLUGIN_ROOT}/skills/gitlab-workflow/scripts/resolve-project.sh)
```

Check if `$PROJECT` matches the current repo's remote:
```bash
git remote get-url origin
```

If they differ, the commit footer needs the full path:
```
Closes group/project#42
```

If they're the same:
```
Closes #42
```

### Step 3: Check staged changes

```bash
git status
git diff --cached --stat
```

If nothing staged, show unstaged diff and ask the user which files to stage.

### Step 4: Determine commit message

Ask the user (or infer from diff):
- **Type**: `feat` / `fix` / `docs` / `style` / `refactor` / `test` / `chore`
- **Scope** (optional): affected module or component
- **Short description**: imperative mood, no capital, no period, max ~72 chars

### Step 5: Compose and commit

**Closing an issue:**
```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

Closes #<id>
EOF
)"
```

**Cross-project close:**
```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

Closes group/project#<id>
EOF
)"
```

**Reference only (no auto-close):**
```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

Related to #<id>
EOF
)"
```

Always use the heredoc form to preserve newlines in the commit message.

### Step 6: Offer next steps

After committing:
- Push: `git push`
- Create MR: `glab mr create --fill`
- Comment on the issue (resolve project first, write in first person):
  ```bash
  glab issue note <id> -R <project> -m "Committed the fix. Opening MR shortly."
  ```

## Notes

- `Closes #N` only auto-closes when merged into the **default branch**
- Omit scope parentheses if scope is unknown: `feat: description`
- Confirm the commit message with the user before committing if unsure
