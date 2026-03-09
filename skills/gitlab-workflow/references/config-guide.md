# .gitlab-workflow Config File

Tells the plugin which GitLab project your issues live in. Create this file at your repo root, paste in any GitLab URL from that project, and you're done.

## Setup

1. Open your GitLab issue board (or any page in the project)
2. Copy the URL from the browser
3. Paste it into `.gitlab-workflow`:

```bash
echo "https://gitlab.example.com/group/project/-/boards" > .gitlab-workflow
echo ".gitlab-workflow" >> .gitignore
```

That's it. Any GitLab URL from that project works — board, issue, MR, pipeline, the project root:

```
# Any of these work:
https://gitlab.example.com/group/project/-/boards
https://gitlab.example.com/group/project/-/boards/1234
https://gitlab.example.com/group/project/-/issues
https://gitlab.example.com/group/project/-/issues/42
https://gitlab.example.com/group/project
```

Comments starting with `#` and blank lines are ignored, so you can annotate the file:

```
# Issue tracker for the mobile team
https://gitlab.example.com/department/mobile-team/sprint-board/-/boards
```

## Resolution Priority

The plugin resolves the project in this order:

| Priority | Source | Example |
|----------|--------|---------|
| 1 | Direct URL argument | Paste a URL when Claude asks |
| 2 | `GITLAB_ISSUE_PROJECT` env var | `export GITLAB_ISSUE_PROJECT=https://.../-/boards` |
| 3 | `.gitlab-workflow` config file | Paste a board URL in the file |
| 4 | Git remote `origin` | Auto-detected when working in the issue project |
| 5 | None found | Claude asks you |

## Config File Discovery

The file is found by walking **up** from the current directory. One file at a monorepo root covers all sub-projects beneath it:

```
~/projects/
├── .gitlab-workflow      ← covers everything below
├── my-api/
└── my-frontend/
```

## Environment Variable

For a global default across all projects, set it in `~/.zshrc` or `~/.bashrc`:

```bash
export GITLAB_ISSUE_PROJECT=https://gitlab.example.com/group/project/-/boards
```
