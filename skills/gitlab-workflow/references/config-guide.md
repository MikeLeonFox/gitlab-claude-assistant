# .gitlab-workflow.json Config File

Links a directory to a GitLab project and tracks the active issue. Useful when issues live in a different repo than the code (e.g. monorepos).

## Setup

```bash
echo '{ "url": "https://gitlab.example.com/group/project/-/boards" }' > .gitlab-workflow.json
echo ".gitlab-workflow.json" >> .gitignore
```

Any GitLab URL from the project works for `url` — board, issue list, MR, or the project root. The plugin extracts the path automatically.

## Fields

| Field | Type | Description |
|---|---|---|
| `url` | string | Any GitLab URL for the project — used to resolve the project path and hostname |
| `issue` | number | Active issue ID — set automatically by `/gitlab-issue <id> start`, cleared by `finish` |

### Example with active issue

```json
{
  "url": "https://gitlab.example.com/group/project/-/boards",
  "issue": 42
}
```

When `issue` is set, `/gitlab-commit` and `/gitlab-issue finish` work without an explicit ID.

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
