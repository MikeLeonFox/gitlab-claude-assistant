# glab CLI Command Reference

## Issue Commands

### `glab issue list`
```
Flags:
  -a, --assignee string     Filter by assignee (@me for self)
  -l, --label strings       Filter by label
  -m, --milestone string    Filter by milestone
  -s, --state string        State: opened, closed, all (default: opened)
  -p, --page int            Page number
      --per-page int        Number per page (max 100)
  -R, --repo string         Target repo (owner/repo or group/sub/repo)
```

### `glab issue view <id>`
```
Flags:
  -c, --comments    Show comments
  -w, --web         Open in browser
  -R, --repo        Target repo
```

### `glab issue create`
```
Flags:
  -t, --title string          Issue title
  -d, --description string    Issue description ("-" opens editor)
  -l, --label strings         Labels
  -a, --assignee strings      Assignees
  -m, --milestone string      Milestone title
      --confidential          Make confidential
  -R, --repo string           Target repo
```

### `glab issue note <id>`
```
Flags:
  -m, --message string    Comment text (required)
  -R, --repo string       Target repo
```

### `glab issue update <id>`
```
Flags:
  -t, --title string          New title
  -d, --description string    New description ("-" opens editor)
  -l, --label strings         Add labels
  -u, --unlabel strings       Remove labels
  -a, --assignee strings      Set assignees (prefix with ! or - to remove, + to add)
      --unassign              Remove all assignees
  -m, --milestone string      Set milestone (0 to unassign)
      --due-date string       Due date (YYYY-MM-DD)
  -w, --weight int            Issue weight
      --lock-discussion       Lock discussion
      --unlock-discussion     Unlock discussion
      --confidential          Make confidential
      --public                Make public
  -R, --repo string           Target repo
```

### `glab issue close <id>` / `glab issue reopen <id>`
```
Flags:
  -R, --repo string    Target repo
```

### `glab issue delete <id>`
```
Flags:
  -R, --repo string    Target repo
```

---

## Merge Request Commands

### `glab mr create`
```
Flags:
  -t, --title string              MR title
  -d, --description string        MR description
  -b, --target-branch string      Target branch (default: default branch)
  -s, --source-branch string      Source branch (default: current branch)
  -l, --label strings             Labels
  -a, --assignee strings          Assignees
      --reviewer strings          Reviewers
  -m, --milestone string          Milestone
      --fill                      Auto-fill title/description from branch/commits
      --draft                     Mark as draft
      --remove-source-branch      Delete branch on merge
      --squash                    Squash commits on merge
  -R, --repo string               Target repo
```

### `glab mr for <issue-id>`
Creates an MR directly linked to an issue. Auto-fills branch and title.
```
Flags:
  -b, --target-branch string    Target branch
      --draft                   Mark as draft
  -R, --repo string             Target repo
```

### `glab mr list`
```
Flags:
  -a, --assignee string     Filter by assignee
  -l, --label strings       Filter by label
  -s, --state string        State: opened, closed, merged, all
      --reviewer string     Filter by reviewer
  -R, --repo string         Target repo
```

### `glab mr view <id|branch>`
```
Flags:
  -c, --comments    Show comments
  -w, --web         Open in browser
  -R, --repo        Target repo
```

### `glab mr note <id|branch>`
```
Flags:
  -m, --message string    Comment text
  -R, --repo string       Target repo
```

### `glab mr merge <id|branch>`
```
Flags:
      --squash              Squash commits
      --remove-source-branch    Delete branch after merge
      --when-pipeline-succeeds  Merge when pipeline passes
  -R, --repo string         Target repo
```

### `glab mr approve <id|branch>` / `glab mr revoke <id|branch>`

### `glab mr checkout <id|branch>`
Checks out MR branch locally.

---

## Auth Commands

```bash
glab auth login       # Authenticate
glab auth status      # Check authentication
glab auth logout      # Log out
```

---

## Config / Repo Commands

```bash
glab config set git_protocol https    # Set git protocol
glab repo view                         # View current repo info
glab repo list                         # List repos in org
```

---

## Tips

### Working with the current directory's repo
When inside a git repo cloned from GitLab, glab auto-detects the project. No `-R` flag needed.

### Specifying multiple labels
```bash
glab issue update 42 --label "bug,in-progress"
# or
glab issue update 42 --label bug --label in-progress
```

### Specifying multiple assignees
```bash
glab issue update 42 --assignee user1,user2
# Add without removing existing:
glab issue update 42 --assignee +user2
# Remove one:
glab issue update 42 --assignee -user1
```
