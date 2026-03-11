---
name: gitlab-workflow
description: Expert guidance for using the GitLab CLI (glab) to manage GitLab issues, merge requests, CI/CD pipelines, repositories, and other GitLab operations. Use this skill when the user needs to interact with GitLab resources — including "comment on a GitLab issue", "add a note to an issue", "move an issue", "update issue labels", "assign an issue", "reference an issue in a commit", "close an issue via commit", "link a commit to an issue", "create a merge request for an issue", "open a GitLab MR", "transition an issue", "start working on an issue", "finish an issue", "monitor CI/CD", "trigger a pipeline", or mentions GitLab issue numbers (e.g. "#42", "issue 42").
version: 2.0.0
allowed-tools: Bash, Read, Grep, Glob
---

# GitLab Workflow Automation

Automates GitLab project management using the `glab` CLI: commenting on issues, moving/updating issues, referencing issues in commits, managing merge requests, monitoring CI/CD pipelines, and repository operations.

## Prerequisites

Verify glab is installed before executing commands:
```bash
glab --version
```

If not installed, inform the user and provide platform-specific installation guidance (e.g. `brew install glab` on macOS).

## Critical Rules

### Rule 1: Always Comment as the User — Never as Claude

Comments posted via `glab` appear under the authenticated GitLab account (the user's own account). Never break this illusion:

- Write comments in **first person** from the user's perspective
- Never prefix comments with "Claude:", "AI:", "Note from AI:", or anything that signals automation
- Mirror the user's tone — casual if they're casual, technical if they're technical
- When the user says "comment saying I'm starting work", write: `"Starting work on this."` — not `"The user is starting work on this."`
- When unsure of the exact wording, ask the user to confirm before posting

**Examples:**

| User says | Comment to post |
|---|---|
| "comment that I'm starting work on this" | `"Starting work on this."` |
| "say I'm blocked waiting for design assets" | `"Blocked — waiting for design assets from the design team."` |
| "comment that the fix is in MR !23" | `"Fix is up in !23 for review."` |
| "tell them I need more info on the acceptance criteria" | `"Could you clarify the acceptance criteria for this? Specifically [...]"` |

Always confirm the comment text with the user before posting if the wording isn't explicit.

### Rule 2: Verify Auth Identity Before First Comment

Before posting any comment in a session, check who glab is authenticated as:

```bash
glab auth status
```

Confirm the username matches who the user expects. If not, prompt them to re-authenticate:
```bash
glab auth login
```

---

## Authentication

```bash
# Interactive authentication
glab auth login

# Check authentication status
glab auth status

# For self-hosted GitLab
glab auth login --hostname gitlab.example.org

# Using environment variables
export GITLAB_TOKEN=your-token
export GITLAB_HOST=gitlab.example.org  # for self-hosted
```

---

## Resolving the GitLab Hostname

Before using `glab api`, you must know the GitLab hostname. Default is `gitlab.com`, but for self-hosted instances this will be wrong. Always resolve it — **never assume `gitlab.com`**.

**Resolution order:**

1. `.gitlab-workflow.json` — extract hostname from `url` field
2. `GITLAB_HOST` environment variable
3. Git remote `origin` — only if hostname is NOT `github.com` or `bitbucket.org`
4. `glab auth status` — find the logged-in non-`gitlab.com` host
5. Fall back to `gitlab.com`

**Detection script:**
```bash
GITLAB_HOST=$(
  # 1. .gitlab-workflow.json
  root=$(git rev-parse --show-toplevel 2>/dev/null) && \
  h=$(jq -r '.url // empty' "$root/.gitlab-workflow.json" 2>/dev/null | sed -E 's|https?://([^/]+)/.*|\1|' | grep -v '^$') && \
  [[ -n "$h" ]] && echo "$h" && exit
  # 2. GITLAB_HOST env var
  [[ -n "${GITLAB_HOST:-}" ]] && echo "$GITLAB_HOST" && exit
  # 3. Git remote (skip github/bitbucket)
  remote=$(git remote get-url origin 2>/dev/null) && \
  h=$(echo "$remote" | sed -E 's|https?://([^/]+)/.*|\1|; s|git@([^:]+):.*|\1|') && \
  echo "$h" | grep -Eqv 'github\.com|bitbucket\.org' && echo "$h" && exit
  # 4. glab auth status — first logged-in non-gitlab.com host
  glab auth status 2>&1 | grep -E 'Logged in to' | grep -v 'gitlab\.com' | sed -E 's/.*Logged in to ([^ ]+).*/\1/' | head -1 && exit
  echo "gitlab.com"
) 2>/dev/null
```

Always pass `--hostname "$GITLAB_HOST"` to all `glab api` calls:
```bash
glab api --hostname "$GITLAB_HOST" "issues?scope=assigned_to_me"
```

---

## Resolving the Right GitLab Project

Issues are often in a **different project** than the current working directory. Always resolve the correct project before running any `glab issue` command.

### Resolution Order (use the first that works)

**Step 1 — Did the user provide a full URL?**

If the user pastes a URL like `https://gitlab.example.com/group/subgroup/project/-/issues/42`, parse it:
- Project path: everything between the host and `/-/` → `group/subgroup/project`
- Issue ID: the number after `/issues/` → `42`

Then run:
```bash
glab issue note 42 -R group/subgroup/project -m "comment"
```

**Step 2 — Use the resolve script:**
```bash
PROJECT=$(bash ${CLAUDE_SKILL_DIR}/scripts/resolve-project.sh)
```

The script checks (in order):
1. `GITLAB_ISSUE_PROJECT` environment variable
2. `.gitlab-workflow` config file (walks up from CWD)
3. Current git remote `origin` (if it's a GitLab remote)

**Step 3 — Ask the user**

If no project can be resolved, ask once:
> "Which GitLab project are these issues in? (e.g. `group/project` or paste a full issue URL)"

Then offer to save it so they don't have to answer again:
```bash
echo '{ "url": "https://gitlab.example.com/group/project/-/boards" }' > .gitlab-workflow.json
echo ".gitlab-workflow.json" >> .gitignore  # keep it local
```

### Config File: `.gitlab-workflow.json`

Create this file at the repo root (or any parent directory) with a `url` key pointing to any GitLab URL from the project.

```json
{
  "url": "https://gitlab.example.com/group/project/-/boards"
}
```

```bash
echo '{ "url": "https://gitlab.example.com/group/project/-/boards" }' > .gitlab-workflow.json
echo ".gitlab-workflow.json" >> .gitignore
```

Any URL from the project works for `url`: board, issue list, a specific issue, MR, the project root. The plugin extracts the project path automatically.

### Using -R Flag

All `glab issue` and `glab mr` commands accept `-R`:
```bash
glab issue note 42 -R group/project -m "comment"
glab issue update 42 -R group/project --label "in-progress"
glab issue view 42 -R group/project
```

For deeply nested groups:
```bash
glab issue note 42 -R department/team/subteam/project -m "comment"
```

---

## Core Workflows

### 1. Comment on an Issue

Resolve the project first, then:

```bash
glab issue note <issue-id> -R <project> -m "Starting work on this."
```

Always write the comment text in first person as the user. Confirm wording before posting.

### 2. Move / Update an Issue

"Moving" means transitioning workflow state via labels, assignee, or milestone.

```bash
# Label transition (e.g. to-do → in-progress)
glab issue update <id> -R <project> --label "in-progress" --unlabel "to-do"

# Assign to self (get username from: glab auth status)
glab issue update <id> -R <project> --assignee <username>

# Set milestone
glab issue update <id> -R <project> --milestone "Sprint 3"

# Combine multiple updates
glab issue update <id> -R <project> --label "in-progress" --unlabel "to-do" --assignee <username>
```

Close or reopen:
```bash
glab issue close <id> -R <project>
glab issue reopen <id> -R <project>
```

### 3. Reference Issues in Commits

Always reference issues in commit messages. The issue and commit repo can be different — the reference still shows up as a cross-project link in GitLab.

**Auto-close on merge (use these keywords):**
```
Closes #42
Fixes #42
Resolves #42
```

**Reference only (no auto-close):**
```
Related to #42
Part of #42
```

**For cross-project references:**
```
Closes group/project#42
```

**Full commit format:**
```
feat(scope): short description

Closes #42
```

See `references/commit-conventions.md` for full format guide.

### 4. Start Working on an Issue

When the user says "start working on issue #42" or "pick up issue 42":

1. Resolve the project path
2. View the issue:
   ```bash
   glab issue view <id> -R <project>
   ```
3. Update state:
   ```bash
   glab issue update <id> -R <project> --label "in-progress" --unlabel "to-do" --assignee <username>
   ```
4. Post a start comment (first person, confirm wording):
   ```bash
   glab issue note <id> -R <project> -m "Starting work on this."
   ```
5. Create a branch in the code repo:
   ```bash
   git checkout -b feat/issue-<id>-short-description
   ```

### 5. Finish an Issue / Open MR

When the user says "finish issue #42" or "open MR for issue 42":

1. Commit with closing reference:
   ```bash
   git commit -m "feat: description

   Closes #<id>"
   ```
2. Push:
   ```bash
   git push -u origin <branch>
   ```
3. Create MR:
   ```bash
   glab mr create --fill --target-branch main
   ```
4. Update issue labels:
   ```bash
   glab issue update <id> -R <project> --label "review" --unlabel "in-progress"
   ```
5. Comment with MR reference (first person):
   ```bash
   glab issue note <id> -R <project> -m "MR up for review: !<mr-number>"
   ```

### 6. List Issues

```bash
glab issue list -R <project>
glab issue list -R <project> --label "in-progress"
glab issue list -R <project> --assignee @me
```

**Listing all issues assigned to you (across all projects):**

`glab issue list --assignee @me` is repo-scoped and returns nothing if the current repo has no issues. For a global search across all projects, resolve the hostname first (see **Resolving the GitLab Hostname** above), then use the API:

```bash
# After resolving GITLAB_HOST...
glab api --hostname "$GITLAB_HOST" "issues?scope=assigned_to_me&state=opened" | jq -r '.[] | "[\(.labels | map(select(startswith("status::"))) | first // "no status")] \(.references.full) — \(.title)"'
```

To also show closed issues:
```bash
glab api --hostname "$GITLAB_HOST" "issues?scope=assigned_to_me&state=all" | jq -r '.[] | "[\(.state)] \(.references.full) — \(.title)"'
```

### 7. Reviewing Merge Requests

```bash
# List MRs awaiting your review
glab mr list --reviewer=@me

# Checkout MR locally to test
glab mr checkout <mr-number>

# Approve MR after testing
glab mr approve <mr-number>

# Add review comment
glab mr note <mr-number> -m "Please update tests"
```

### 8. Monitoring CI/CD

```bash
# Watch pipeline in progress (interactive)
glab pipeline ci view

# Check pipeline status
glab ci status

# View logs if failed
glab ci trace

# Retry failed pipeline
glab ci retry

# Trigger a pipeline
glab ci run

# Lint CI config before pushing
glab ci lint
```

---

## Common Patterns

### Working Outside Repository Context

When not in a Git repository, specify the repository:
```bash
glab mr list -R owner/repo
glab issue list -R owner/repo
```

### Self-Hosted GitLab

```bash
export GITLAB_HOST=gitlab.example.org
# or per-command
glab repo clone gitlab.example.org/owner/repo
```

### Using the API Command

```bash
# Basic GET request
glab api projects/:id/merge_requests

# IMPORTANT: Pagination uses query parameters in URL, NOT flags
# ❌ WRONG: glab api --per-page=100 projects/:id/jobs
# ✓ CORRECT: glab api "projects/:id/jobs?per_page=100"

# Auto-fetch all pages
glab api --paginate "projects/:id/pipelines/123/jobs?per_page=100"

# POST with data
glab api --method POST projects/:id/issues --field title="Bug" --field description="Details"
```

### JSON Output for Scripting

```bash
glab mr list --output=json | jq '.[] | .title'
```

---

## Common Issues Quick Fixes

**"command not found: glab"** — Install glab or verify PATH

**"401 Unauthorized"** — Run `glab auth login`

**"404 Project Not Found"** — Verify repository name and access permissions

**"not a git repository"** — Navigate to repo or use `-R owner/repo` flag

**"source branch already has a merge request"** — Use `glab mr list` to find existing MR

For detailed troubleshooting, load **references/troubleshooting.md**.

---

## Best Practices

1. **Verify authentication** before executing commands: `glab auth status`
2. **Use `--help`** to explore command options: `glab <command> --help`
3. **Link MRs to issues** using "Closes #123" in MR description or commit
4. **Lint CI config** before pushing: `glab ci lint`
5. **Check repository context** when commands fail: `git remote -v`
6. **Use JSON output** for scripting: `--output=json`

---

## Additional Resources

Load these references only when needed for deeper detail:

- **`references/glab-commands.md`** — Full glab flag reference for all commands (issues, MRs, CI/CD, repos, labels, releases, variables, etc.)
- **`references/quick-reference.md`** — Condensed command cheat sheet
- **`references/commit-conventions.md`** — Conventional commit format and GitLab auto-close keywords
- **`references/config-guide.md`** — `.gitlab-workflow` config file setup
- **`references/troubleshooting.md`** — Detailed error scenarios and solutions
- **`scripts/resolve-project.sh`** — Script to resolve the correct GitLab project path
