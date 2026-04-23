# glab Commands - Detailed Reference

This is a comprehensive reference for all glab commands. Load this file when detailed command information is needed.

## Merge Requests (MR)

### Listing Merge Requests
```bash
# List MRs assigned to you
glab mr list --assignee=@me

# List MRs where you're a reviewer
glab mr list --reviewer=@me

# List all open MRs
glab mr list

# Filter by state
glab mr list --state=merged
glab mr list --state=closed
glab mr list --state=all
```

### Creating Merge Requests
```bash
# Create MR from current branch (interactive)
glab mr create

# Create MR with title and description
glab mr create --title "Fix bug" --description "Fixes issue #123"

# Create MR for specific issue
glab mr create 123

# Create draft MR
glab mr create --draft

# Create MR and assign reviewers
glab mr create --reviewer=username1,username2

# Create MR with labels
glab mr create --label="bug,priority:high"

# Create MR with assignee
glab mr create --assignee=username

# Create MR to a specific target branch
glab mr create --target-branch=develop

# Create MR and remove source branch after merge
glab mr create --remove-source-branch

# Auto-fill title/description from commits
glab mr create --fill
```

### `glab mr create` Full Flags
```
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

### Viewing and Interacting with MRs
```bash
# View MR details (opens in browser by default)
glab mr view 123

# View MR in terminal
glab mr view 123 --web=false

# View MR with comments
glab mr view 123 --comments

# Checkout MR branch locally
glab mr checkout 243

# Approve MR
glab mr approve 123

# Unapprove MR
glab mr unapprove 123

# Merge MR
glab mr merge 123

# Merge and delete source branch
glab mr merge 123 --remove-source-branch

# Merge when pipeline succeeds
glab mr merge 123 --when-pipeline-succeeds

# Squash and merge
glab mr merge 123 --squash

# Close MR without merging
glab mr close 123

# Reopen closed MR
glab mr reopen 123

# Add note/comment to MR
glab mr note 123 -m "Looks good to me"

# Update MR title
glab mr update 123 --title "New title"

# Update MR description
glab mr update 123 --description "New description"

# Mark MR as draft
glab mr update 123 --draft

# Mark MR as ready (remove draft status)
glab mr update 123 --ready

# Subscribe to MR notifications
glab mr subscribe 123

# Unsubscribe from MR notifications
glab mr unsubscribe 123
```

### `glab mr for <issue-id>`
Creates an MR directly linked to an issue. Auto-fills branch and title.
```
  -b, --target-branch string    Target branch
      --draft                   Mark as draft
  -R, --repo string             Target repo
```

---

## Issues

### `glab issue list`

> **⚠️ glab 1.92.1 state flags — `--state` does NOT exist.**
> Open is the default. Use `--closed` or `--all` to filter by state.
> `-s` is `--sort`, NOT `--state`. Do not reach for `--state`.

```
Flags:
  -a, --assignee string     Filter by assignee (@me for self)
  -l, --label strings       Filter by label
  -m, --milestone string    Filter by milestone
      --closed              Show only closed issues
      --all                 Show issues in all states
      --search string       Search issues
  -p, --page int            Page number
      --per-page int        Number per page (max 100)
  -R, --repo string         Target repo (owner/repo or group/sub/repo)
```

```bash
# Open issues (default — no flag needed)
glab issue list

# Closed issues
glab issue list --closed

# All issues
glab issue list --all
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

> **⚠️ UNRELIABLE for anything beyond simple one-liners.**
> Shell arg parsing breaks when the message contains backticks, em-dashes,
> parentheses, or newlines — glab receives extra positional args and throws
> `Accepts 1 arg(s), received 2`.
>
> **Mandate: use `glab api` for ALL notes in this project.**

```bash
# ✅ CORRECT — safe for arbitrary markdown
glab api --method POST "projects/:id/issues/ISSUE_NUM/notes" \
  --field "body=Your comment text here — with dashes, `backticks`, (parens), whatever."

# ❌ AVOID — breaks on complex messages
glab issue note 42 -m "Message with `backticks` or em—dashes"
```

```
Flags (avoid in practice — prefer glab api above):
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

### Tips: Specifying Multiple Labels and Assignees
```bash
# Multiple labels
glab issue update 42 --label "bug,in-progress"
# or
glab issue update 42 --label bug --label in-progress

# Multiple assignees
glab issue update 42 --assignee user1,user2
# Add without removing existing:
glab issue update 42 --assignee +user2
# Remove one:
glab issue update 42 --assignee -user1
```

---

## CI/CD Pipelines

### Viewing Pipelines
```bash
# Watch pipeline in progress (interactive)
glab pipeline ci view

# List recent pipelines
glab ci list

# List pipelines with specific status
glab ci list --status=failed
glab ci list --status=success
glab ci list --status=running

# View pipeline status
glab ci status

# View pipeline for specific branch
glab ci status --branch=main

# Get pipeline trace/logs
glab ci trace

# Get trace for specific job
glab ci trace <job-id>

# View pipeline details
glab ci view <pipeline-id>

# Delete a pipeline
glab ci delete <pipeline-id>
```

### Triggering and Managing Pipelines
```bash
# Run/trigger pipeline
glab ci run

# Run pipeline for specific branch
glab ci run --branch=develop

# Run pipeline with variables
glab ci run --variables-file /tmp/variables.json

# Run pipeline with inline variables
glab ci run -V KEY1=value1 -V KEY2=value2

# Retry failed pipeline
glab ci retry

# Retry specific pipeline
glab ci retry <pipeline-id>

# Cancel running pipeline
glab ci cancel

# Cancel specific pipeline
glab ci cancel <pipeline-id>
```

### CI Configuration
```bash
# Lint .gitlab-ci.yml file in current directory
glab ci lint

# Lint specific file
glab ci lint --path=.gitlab-ci.yml

# View CI configuration
glab ci config

# Get CI job artifacts
glab ci artifact <job-id>

# Download artifacts to specific path
glab ci artifact <job-id> -p path/to/download
```

---

## Repository Operations

### Cloning Repositories
```bash
# Clone repository
glab repo clone namespace/project

# Clone to specific directory
glab repo clone namespace/project target-dir

# Clone from self-hosted GitLab
GITLAB_HOST=gitlab.example.org glab repo clone groupname/project

# Clone repository by group (interactive)
glab repo clone -g groupname

# Clone with specific protocol
glab repo clone namespace/project --protocol=ssh
glab repo clone namespace/project --protocol=https
```

### Repository Information and Management
```bash
# View repository details
glab repo view

# View specific repository
glab repo view owner/repo

# View in browser
glab repo view --web

# Fork repository
glab repo fork

# Fork to specific namespace
glab repo fork --clone --namespace=mygroup

# Create repository
glab repo create project-name

# Create private repository
glab repo create project-name --private

# Create repository with description
glab repo create project-name --description "My project"

# Archive repository
glab repo archive owner/project

# Delete repository
glab repo delete owner/project
```

---

## API Access

### Making API Calls
```bash
# GET request
glab api projects/:id/merge_requests

# GET with specific project ID
glab api projects/12345/merge_requests

# POST request with data
glab api --method POST projects/:id/issues --field title="Bug report"

# POST with multiple fields
glab api --method POST projects/:id/issues \
  --field title="Bug" \
  --field description="Description here" \
  --field labels="bug,priority:high"

# PUT request
glab api --method PUT projects/:id/merge_requests/1 --field title="New Title"

# DELETE request
glab api --method DELETE projects/:id/issues/123

# Paginated API request (auto-fetches all pages)
glab api --paginate projects/:id/issues

# IMPORTANT: Pagination with query parameters (specify per_page in URL)
# ❌ WRONG: glab api --per-page=100 projects/:id/jobs
# ✓ CORRECT: glab api "projects/:id/jobs?per_page=100"

# Combine pagination flag with query parameters
glab api --paginate "projects/:id/merge_requests?per_page=50&state=opened"

# Include response headers
glab api --include projects/:id

# Silent mode (no progress)
glab api --silent projects/:id/merge_requests
```

---

## Labels

```bash
# List all labels
glab label list

# Create label
glab label create "bug" --color="#FF0000"

# Create label with description
glab label create "feature" --color="#00FF00" --description "New features"

# Delete label
glab label delete "old-label"
```

---

## Releases

```bash
# List releases
glab release list

# Create release
glab release create v1.0.0

# Create release with notes
glab release create v1.0.0 --notes "Release notes here"

# Create release from file
glab release create v1.0.0 --notes-file CHANGELOG.md

# View specific release
glab release view v1.0.0

# Download release assets
glab release download v1.0.0

# Delete release
glab release delete v1.0.0
```

---

## Variables (CI/CD)

```bash
# List variables
glab variable list

# Get specific variable
glab variable get VAR_NAME

# Set/create variable
glab variable set VAR_NAME value

# Set protected variable
glab variable set VAR_NAME value --protected

# Set masked variable
glab variable set VAR_NAME value --masked

# Update variable
glab variable update VAR_NAME new-value

# Delete variable
glab variable delete VAR_NAME

# Export variables
glab variable export > variables.json

# Import variables
glab variable import < variables.json
```

---

## Pipeline Schedules

```bash
# List pipeline schedules
glab schedule list

# Create schedule
glab schedule create --cron "0 2 * * *" --ref main --description "Nightly build"

# Run schedule immediately
glab schedule run <schedule-id>

# Delete schedule
glab schedule delete <schedule-id>
```

---

## Additional Commands

### User Operations
```bash
# View current user information
glab user view

# View specific user
glab user view username
```

### SSH Keys
```bash
# List SSH keys
glab ssh-key list

# Add SSH key
glab ssh-key add ~/.ssh/id_rsa.pub --title "Work laptop"

# Delete SSH key
glab ssh-key delete <key-id>
```

### Snippets
```bash
# List snippets
glab snippet list

# Create snippet from file
glab snippet create --title "Script" myfile.sh

# Create private snippet
glab snippet create --title "Secret" --private secret.txt

# View snippet
glab snippet view <snippet-id>

# Delete snippet
glab snippet delete <snippet-id>
```

### Aliases
```bash
# Create alias
glab alias set co "mr checkout"

# List aliases
glab alias list

# Delete alias
glab alias delete co
```

---

## Common Flags Across Commands

Most glab commands support these common flags:

- `--help`, `-h` — Show help for command
- `--repo`, `-R` — Specify repository (format: OWNER/REPO)
- `--web`, `-w` — Open in web browser
- `--output`, `-o` — Output format (json, text, etc.)
- `--verbose` — Enable verbose output
- `--page`, `-p` — Page number for paginated results
- `--per-page`, `-P` — Number of items per page

## Output Formats

Many commands support different output formats:

```bash
# JSON output (useful for scripting)
glab mr list --output=json

# Pipe to jq for processing
glab mr list --output=json | jq '.[] | .title'
```

## Configuration Commands

```bash
# View all configuration
glab config get

# Get specific config value
glab config get editor

# Set configuration value
glab config set editor vim

# Common config keys:
# - editor: preferred text editor
# - browser: web browser to use
# - glamour_style: style for terminal rendering
# - host: default GitLab host
```

## Version and Updates

```bash
# Show glab version
glab version

# Check for updates
glab check-update
```
