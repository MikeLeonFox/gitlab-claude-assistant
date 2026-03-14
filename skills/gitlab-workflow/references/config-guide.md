# .gitlab-workflow.json Config File

Links a directory to a GitLab project. Useful when issues live in a different repo than the code (e.g. monorepos).

## Setup

```bash
echo '{ "url": "https://gitlab.example.com/group/project/-/boards" }' > .gitlab-workflow.json
echo ".gitlab-workflow.json" >> .gitignore
```

Any GitLab URL from the project works for `url` — board, issue list, MR, or the project root. The plugin extracts the path automatically.

## Resolution Priority

| Priority | Source |
|---|---|
| 1 | URL passed directly in message |
| 2 | `GITLAB_ISSUE_PROJECT` env var |
| 3 | `.gitlab-workflow.json` (walks up from CWD) |
| 4 | Git remote `origin` |
| 5 | Claude asks |

## Monorepo

One file at the root covers all sub-projects beneath it:

```
~/projects/
├── .gitlab-workflow.json   ← covers everything below
├── my-api/
└── my-frontend/
```

## Global Default

```bash
export GITLAB_ISSUE_PROJECT=https://gitlab.example.com/group/project/-/boards
```
