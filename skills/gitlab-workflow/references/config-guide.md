# .gitlab-workflow.json Config File

Tells the plugin which GitLab project your issues live in. Create this file at your repo root with a `url` key pointing to any GitLab URL from that project.

## Setup

1. Open your GitLab issue board (or any page in the project)
2. Copy the URL from the browser
3. Create `.gitlab-workflow.json`:

```bash
echo '{ "url": "https://gitlab.example.com/group/project/-/boards" }' > .gitlab-workflow.json
echo ".gitlab-workflow.json" >> .gitignore
```

## Format

```json
{
  "url": "https://gitlab.example.com/group/project/-/boards"
}
```

Any GitLab URL from the project works for `url` — board, issue list, a specific issue, MR, or the project root:

```json
{ "url": "https://gitlab.example.com/group/project/-/boards" }
{ "url": "https://gitlab.example.com/group/project/-/boards/1234" }
{ "url": "https://gitlab.example.com/group/project/-/issues" }
{ "url": "https://gitlab.example.com/group/project/-/issues/42" }
{ "url": "https://gitlab.example.com/group/project" }
```

You can add extra fields for your own reference — the script only reads `url`:

```json
{
  "url": "https://gitlab.example.com/department/mobile-team/sprint-board/-/boards",
  "description": "Issue tracker for the mobile team",
  "team": "mobile"
}
```

## Resolution Priority

The plugin resolves the project in this order:

| Priority | Source | Example |
|----------|--------|---------|
| 1 | Direct URL argument | Paste a URL when Claude asks |
| 2 | `GITLAB_ISSUE_PROJECT` env var | `export GITLAB_ISSUE_PROJECT=https://.../-/boards` |
| 3 | `.gitlab-workflow.json` config file | `{ "url": "https://..." }` |
| 4 | Git remote `origin` | Auto-detected when working in the issue project |
| 5 | None found | Claude asks you |

## Config File Discovery

The file is found by walking **up** from the current directory. One file at a monorepo root covers all sub-projects beneath it:

```
~/projects/
├── .gitlab-workflow.json   ← covers everything below
├── my-api/
└── my-frontend/
```

## Environment Variable

For a global default across all projects, set it in `~/.zshrc` or `~/.bashrc`:

```bash
export GITLAB_ISSUE_PROJECT=https://gitlab.example.com/group/project/-/boards
```
