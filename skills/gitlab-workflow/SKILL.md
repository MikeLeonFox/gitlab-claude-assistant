---
name: gitlab-workflow
description: Expert guidance for using the GitLab CLI (glab) to manage GitLab issues, merge requests, CI/CD pipelines, repositories, and other GitLab operations. Use this skill when the user needs to interact with GitLab resources — including "comment on a GitLab issue", "add a note to an issue", "move an issue", "update issue labels", "assign an issue", "reference an issue in a commit", "close an issue via commit", "link a commit to an issue", "create a merge request for an issue", "open a GitLab MR", "transition an issue", "start working on an issue", "finish an issue", "monitor CI/CD", "trigger a pipeline", or mentions GitLab issue numbers (e.g. "#42", "issue 42").
version: 2.0.0
allowed-tools: Bash, Read, Grep, Glob
---

# GitLab Workflow Automation

Automates GitLab project management using the `glab` CLI.

## Prerequisites

```bash
glab --version  # if missing: brew install glab
```

## Critical Rules

### Rule 1: Comment as the User — Never as Claude

Comments post under the authenticated GitLab account. Always write **first person** as the user. Never use "Claude:", "AI:", or any automation signal.

| User says | Post |
|---|---|
| "comment I'm starting work" | `"Starting work on this."` |
| "say I'm blocked on design" | `"Blocked — waiting on design assets."` |

Confirm wording before posting if not explicit.

### Rule 2: Verify Auth Before First Comment

```bash
glab auth status  # confirm username matches who the user expects to post as
```

---

## Authentication

```bash
glab auth login                                # interactive
glab auth login --hostname gitlab.example.org  # self-hosted
export GITLAB_TOKEN=your-token                 # env var alternative
```

---

## Resolving the GitLab Hostname

Never assume `gitlab.com`. Always resolve — **never hardcode**.

Resolution order: `.gitlab-workflow.json` url field → `GITLAB_HOST` env var → git remote origin (skip github/bitbucket) → `glab auth status` first non-gitlab.com host → fall back to `gitlab.com`.

```bash
GITLAB_HOST=$(
  root=$(git rev-parse --show-toplevel 2>/dev/null) && \
  h=$(jq -r '.url // empty' "$root/.gitlab-workflow.json" 2>/dev/null | sed -E 's|https?://([^/]+)/.*|\1|' | grep -v '^$') && \
  [[ -n "$h" ]] && echo "$h" && exit
  [[ -n "${GITLAB_HOST:-}" ]] && echo "$GITLAB_HOST" && exit
  remote=$(git remote get-url origin 2>/dev/null) && \
  h=$(echo "$remote" | sed -E 's|https?://([^/]+)/.*|\1|; s|git@([^:]+):.*|\1|') && \
  echo "$h" | grep -Eqv 'github\.com|bitbucket\.org' && echo "$h" && exit
  glab auth status 2>&1 | grep -E 'Logged in to' | grep -v 'gitlab\.com' | sed -E 's/.*Logged in to ([^ ]+).*/\1/' | head -1 && exit
  echo "gitlab.com"
) 2>/dev/null
```

Always pass `--hostname "$GITLAB_HOST"` to all `glab api` calls.

---

## Resolving the Right Project

Issues are often in a **different project** than the working directory. Always resolve first.

**If user provides a full URL** (`https://gitlab.example.com/group/project/-/issues/42`):
- Project path: between host and `/-/` → `group/project`
- Issue ID: number after `/issues/` → `42`

**Otherwise:**
```bash
PROJECT=$(bash ${CLAUDE_SKILL_DIR}/scripts/resolve-project.sh)
```
Checks: `GITLAB_ISSUE_PROJECT` env var → `.gitlab-workflow.json` → git remote origin.

**If nothing found, ask once:**
> "Which GitLab project? (e.g. `group/project` or paste the full issue URL)"

Offer to save:
```bash
echo '{ "url": "https://gitlab.example.com/group/project/-/boards" }' > .gitlab-workflow.json
echo ".gitlab-workflow.json" >> .gitignore
```

All `glab issue` / `glab mr` commands accept `-R group/project` (supports nested: `dept/team/sub/project`).

---

## Core Workflows

### Comment
```bash
glab issue note <id> -R <project> -m "Starting work on this."
```

### Update / Move Issue
```bash
glab issue update <id> -R <project> --label "in-progress" --unlabel "to-do" --assignee <username>
glab issue close <id> -R <project>
```

### Commit with Issue Reference
```
feat(scope): description

Closes #42             # auto-closes on merge to default branch
Related to #42         # reference only
Closes group/project#42  # cross-project
```

### Start Issue
1. `glab issue view <id> -R <project>`
2. `glab issue update <id> -R <project> --label "in-progress" --unlabel "to-do" --assignee <username>`
3. `glab issue note <id> -R <project> -m "Starting work on this."`
4. `git checkout -b feat/issue-<id>-short-description`

### Finish Issue / Open MR
1. Commit with `Closes #<id>` footer
2. `git push -u origin <branch>`
3. `glab mr create --fill --target-branch main`
4. `glab issue update <id> -R <project> --label "review" --unlabel "in-progress"`
5. `glab issue note <id> -R <project> -m "MR up for review: !<mr-number>"`

### List Issues
```bash
glab issue list -R <project> --label "in-progress"
# Global (all projects):
glab api --hostname "$GITLAB_HOST" "issues?scope=assigned_to_me&state=opened" | jq -r '.[] | "[\(.labels | map(select(startswith("status::"))) | first // "no status")] \(.references.full) — \(.title)"'
```

### CI/CD
```bash
glab pipeline ci view  # watch live
glab ci status         # check status
glab ci trace          # view logs
glab ci retry          # retry failed
glab ci run            # trigger
glab ci lint           # lint config
```

### MR Review
```bash
glab mr list --reviewer=@me
glab mr checkout <mr-number>
glab mr approve <mr-number>
```

### API
```bash
# Pagination must be in URL, not flags:
glab api --paginate "projects/:id/pipelines/123/jobs?per_page=100"
glab mr list --output=json | jq '.[] | .title'
```

---

## Common Errors

| Error | Fix |
|---|---|
| `command not found: glab` | `brew install glab` |
| `401 Unauthorized` | `glab auth login` |
| `404 Project Not Found` | check `-R` value and permissions |
| `not a git repository` | use `-R owner/repo` |
| `source branch already has a MR` | `glab mr list` to find it |

---

## Reference Files (load only when needed)

- `references/glab-commands.md` — full flag reference
- `references/quick-reference.md` — command cheat sheet
- `references/commit-conventions.md` — conventional commit format
- `references/config-guide.md` — `.gitlab-workflow.json` setup
- `references/troubleshooting.md` — detailed error scenarios
- `scripts/resolve-project.sh` — project resolution script
