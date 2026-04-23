---
name: gitlab-workflow
description: Expert guidance for using the GitLab CLI (glab) to manage GitLab issues, merge requests, CI/CD pipelines, repositories, and other GitLab operations. Use this skill when the user needs to interact with GitLab resources — including "comment on a GitLab issue", "add a note to an issue", "move an issue", "update issue labels", "assign an issue", "reference an issue in a commit", "close an issue via commit", "link a commit to an issue", "create a merge request for an issue", "open a GitLab MR", "transition an issue", "start working on an issue", "finish an issue", "monitor CI/CD", "trigger a pipeline", or mentions GitLab issue numbers (e.g. "#42", "issue 42").
version: 2.2.0
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

### Rule 3: Use `glab api` for ALL Notes / Comments — Never `glab issue note`

`glab issue note -m "..."` breaks on backticks, em-dashes, parentheses, or newlines
(`Accepts 1 arg(s), received 2`). Always use the API directly:

```bash
# ✅ Safe for arbitrary markdown
glab api --method POST "projects/:id/issues/ISSUE_NUM/notes" \
  --field "body=Your comment here."
```

### Rule 4: No `--state` flag on `glab issue list` (glab 1.92.1)

`--state` does not exist. `-s` is `--sort`. Open is default; use `--closed` or `--all`.

```bash
glab issue list           # open (default)
glab issue list --closed  # closed
glab issue list --all     # all states
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

```bash
GITLAB_HOST=$(bash ${CLAUDE_SKILL_DIR}/scripts/resolve-host.sh)
export GITLAB_HOST  # glab picks this up automatically — no --hostname flag needed
```

> **CRITICAL:** `--hostname` is only valid for `glab auth login`. It does **NOT** exist on `glab issue`, `glab mr`, `glab api`, or any other subcommand — passing it will fail with `Unknown flag: --hostname`. Always use `export GITLAB_HOST` instead.

Resolution order: `.gitlab-workflow.json` url → `GITLAB_HOST` env var → git remote origin (skips github/bitbucket) → `glab auth status` first non-gitlab.com host → `gitlab.com`.

---

## Resolving the Right Project

Issues are often in a **different project** than the working directory. Always resolve first.

**If user provides a full URL** (`https://gitlab.example.com/group/project/-/issues/42`):
- Project path: between host and `/-/` → `group/project`
- Issue ID: number after `/issues/` → `42`

**If `.gitlab-workflow.json` has a `url` field** (primary source — use it directly):
```bash
root=$(git rev-parse --show-toplevel 2>/dev/null) || root="."
GITLAB_URL=$(jq -r '.url // empty' "$root/.gitlab-workflow.json" 2>/dev/null)
GITLAB_HOST=$(echo "$GITLAB_URL" | sed 's|https://||' | cut -d'/' -f1)
PROJECT=$(echo "$GITLAB_URL" | sed 's|https://[^/]*/||; s|/-/.*||')
export GITLAB_HOST
```
When the project path comes from the config url, always use the full `group/project#N` form in commit footers — do not compare against git remote.

**Otherwise (fallback):**
```bash
PROJECT=$(bash ${CLAUDE_SKILL_DIR}/scripts/resolve-project.sh)
```
Checks: `GITLAB_ISSUE_PROJECT` env var → `.gitlab-workflow.json` project field → git remote origin.

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

### Issueboard Workflow (with commit auto-mention)

Full cycle for working from an issue board — every commit auto-posts to the linked issue:

1. **Start** — `/gitlab-issue 42 start` → assigns, labels, branches, comments, saves `"issue": 42` to `.gitlab-workflow.json`
2. **Commit** — `/gitlab-commit` → reads saved issue ID, conventional commit with `Closes #N` or `Related to #N` footer
3. **Finish** — `/gitlab-issue finish` → MR, label update, MR link posted to issue, clears `issue` from config

Issue ID is saved on `start` and cleared on `finish` — no need to repeat it for every commit or finish.

GitLab automatically cross-references commits in the issue timeline when pushed — no manual note needed. Cross-project references (`group/project#N`) only appear in the issue if the pusher has Reporter access to that project; if not, the reference is silently ignored and a manual note is needed.

### Fix Issue Labels & Epic

Use when user says an issue "needs the right labels", "needs to match other issues", "normalize", "fix up", or "align with siblings".

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fix-issue-labels-and-epic.sh <issue_iid>
```

Fetches all open sibling issues, finds the most common namespaced label per namespace (`project::X`, `status::X`, `tribe::X`, etc.), applies missing ones to the target, removes orphan labels (non-namespaced and absent from all siblings), and links the most common epic if siblings share one. Prints a summary of all changes.

### Start Issue
1. `glab issue view <id> -R <project>`
2. Check board labels: `glab issue list -R <project> --output=json | jq -r '.[].labels[]?' | sort -u`
3. `glab issue update <id> -R <project> --label "in-progress" --unlabel "to-do" --assignee <username>` (use scoped labels like `status::in-progress` if the board uses them)
4. `glab issue note <id> -R <project> -m "Starting work on this."`
5. `git checkout -b feat/issue-<id>-short-description`

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
glab api "issues?scope=assigned_to_me&state=opened" | jq -r '.[] | "[\(.labels | map(select(startswith("status::"))) | first // "no status")] \(.references.full) — \(.title)"'
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
| `Unknown flag: --hostname` | Use `export GITLAB_HOST=...` — `--hostname` only works with `glab auth login` |

---

## Reference Files (load only when needed)

- `references/glab-commands.md` — full flag reference
- `references/quick-reference.md` — command cheat sheet
- `references/commit-conventions.md` — conventional commit format
- `references/config-guide.md` — `.gitlab-workflow.json` setup
- `references/troubleshooting.md` — detailed error scenarios
- `scripts/resolve-project.sh` — project resolution script
- `scripts/resolve-host.sh` — hostname resolution script
- `scripts/fix-issue-labels-and-epic.sh` — normalize issue labels and epic to match sibling issues
