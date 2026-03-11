## 1. Project Overview

| Item                      | Value                                                                                                                                  |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Project name**          | `gitlab-claude-assistant`                                                                                                              |
| **Primary goal**          | Automate issue management, commit‑to‑issue linking, pipeline configuration, and code‑review tasks in a GitLab repository using Claude. |
| **Core personas**         | Developers, Product Owners, QA Engineers, Ops Engineers                                                                                |
| **Deployment**            | CLI + optional Web UI; Dockerised CI helper that runs in GitLab CI.                                                                    |
| **Target GitLab version** | 15.x+ (REST v4 + GraphQL)                                                                                                              |

---

## 2. Repository Skeleton

```
gitlab-claude-assistant/
├── .claude.yaml          # Config template (see Section 6)
├── README.md             # This file
├── cli/
│   ├── __init__.py
│   ├── main.py           # Click / Typer entry point
│   └── prompts/
│       ├── issue_create.md
│       ├── commit_link.md
│       ├── weight_estimate.md
│       └── test_generation.md
├── ci/
│   ├── Dockerfile
│   ├── claude_ci.sh
│   └── requirements.txt
├── tests/
│   ├── test_cli.py
│   └── test_ci.py
└── .gitlab-ci.yml
```

---

## 3. High‑Level Architecture

```mermaid
graph TD
    A[User (CLI/Web UI)] -->|Command| B[Claude Wrapper]
    B -->|Prompt| C[Claude LLM]
    C -->|Response| B
    B -->|GitLab Ops| D[GitLab API]
    D -->|CRUD| E[Repository State]
    B -->|CI Job| F[Dockerised CI Helper]
    F -->|Lint / Tests / Docs| G[GitLab Runner]
```

- **Claude Wrapper** – Handles prompt construction, token usage, caching, and error handling.
- **GitLab API** – Uses `python-gitlab` SDK or equivalent; all CRUD ops are batched where possible.
- **CI Helper** – A Docker image that runs as a job in the pipeline; contains the same CLI for local testing.

---

## 4. Feature Set (Detailed)

| Feature                     | Command                      | Prompt File                  | Notes                                                                        |
| --------------------------- | ---------------------------- | ---------------------------- | ---------------------------------------------------------------------------- |
| **Auto‑config & Init**      | `claude init`                | –                            | Generates `.claude.yaml`, sets up GitLab hooks, creates default board.       |
| **Issue Creation**          | `claude create`              | `prompts/issue_create.md`    | Conversational dialog: title → body → labels → assignee → weight.            |
| **Commit‑to‑Issue Linking** | `claude link-commit <sha>`   | `prompts/commit_link.md`     | Detects issue refs or creates a draft issue.                                 |
| **Weight Estimation**       | `claude estimate <issue-id>` | `prompts/weight_estimate.md` | Returns numeric estimate + confidence.                                       |
| **Test Generation**         | `claude test <file_path>`    | `prompts/test_generation.md` | Generates unit test stubs for the target function.                           |
| **Board Sync**              | `claude board`               | –                            | Auto‑creates/updates a GitLab board with lists Backlog → In‑Progress → Done. |
| **Merge‑Request Helper**    | `claude mr`                  | –                            | Creates branch + MR, auto‑assigns reviewers based on code‑owners.            |
| **Auto‑Merge**              | `claude merge`               | –                            | Runs after pipeline success + `Ready` label; auto‑merges.                    |
| **Analytics**               | `claude analytics`           | –                            | Outputs velocity, cycle time, issue churn.                                   |
| **Chat‑The‑Repo**           | `claude chat`                | –                            | Open‑ended Q&A about the repo (e.g., “What are the biggest blockers?”).      |

---

## 5. Prompt Templates

> **Tip** – Keep each prompt in its own `.md` file. Use placeholders like `{project_name}` that the CLI fills in at runtime.

### 5.1 `prompts/issue_create.md`

```
You are a project manager for the GitLab project "{project_name}".
A developer wants to add a new feature or bug fix: "{user_input}".

Generate a complete issue:
- Title (max 80 chars)
- Body (include acceptance criteria, steps to reproduce if bug)
- Labels (choose from: enhancement, bug, documentation, ui, backend)
- Assignee (default: {default_assignee})
- Weight (estimate in hours, with a confidence score 0‑1)

Respond in JSON with keys: title, body, labels, assignee, weight, confidence.
```

### 5.2 `prompts/commit_link.md`

```
A new commit has been pushed: "{commit_message}" (SHA: {sha}).
Determine the best matching open issue(s) by title or description.
If a match is found, return the issue ID and a concise linking comment.
If no match, propose a new issue title.

Output JSON: { "issue_id": <int>, "comment": "<string>" } or { "suggestion_title": "<string>" }.
```

### 5.3 `prompts/weight_estimate.md`

```
Analyze the issue body (provided below) and estimate the effort in hours.
Consider typical task complexity for the repository language and domain.

Provide:
- Estimated hours (float)
- Confidence score (0‑1)
- Rationale (short, < 50 words)

Output JSON: { "hours": <float>, "confidence": <float>, "rationale": "<string>" }.
```

### 5.4 `prompts/test_generation.md`

````
You are a senior QA engineer. Generate unit tests for the function below in {repo_language}.

File: {file_path}
Function signature: {function_signature}

Output the tests as a single Markdown code block (```) in the target language.
Ensure tests cover edge cases and normal flows.
````

---

## 6. Configuration (`.claude.yaml`)

```yaml
# .claude.yaml – Configuration for gitlab-claude-assistant

project_name: MyApp
board_name: "Development Board"
default_assignee: "@alice"
weight_scale: "hours"
llm:
  provider: "anthropic"
  model: "claude-3.5-sonnet"
  max_retries: 3
  temperature: 0.2
gitlab:
  api_url: "https://gitlab.com/api/v4"
  auth_token_env: "GITLAB_TOKEN" # Should be set as CI variable
ci:
  docker_image: "gitlab-claude-assistant:latest"
  lint_tool: "ruff" # or any other linter
  test_tool: "pytest"
  doc_tool: "mkdocs"
```

- **`auth_token_env`** – The name of the environment variable that contains the personal access token.
- **`ci.docker_image`** – The tag of the Docker image to run in the CI pipeline.

---

## 7. GitLab CI Configuration (`.gitlab-ci.yml`)

```yaml
stages:
  - lint
  - test
  - docs
  - merge

variables:
  CLAUDE_TOKEN: $CLAUDE_TOKEN # Provided by the user
  GITLAB_TOKEN: $GITLAB_TOKEN # Provided by the repo

lint:
  stage: lint
  image: $CI_PROJECT_DIR/ci/Dockerfile
  script:
    - claude_ci lint
  artifacts:
    paths:
      - lint_report.txt

test:
  stage: test
  image: $CI_PROJECT_DIR/ci/Dockerfile
  script:
    - claude_ci test
  artifacts:
    paths:
      - test_report.xml

docs:
  stage: docs
  image: $CI_PROJECT_DIR/ci/Dockerfile
  script:
    - claude_ci docs
  artifacts:
    paths:
      - docs/

merge:
  stage: merge
  image: $CI_PROJECT_DIR/ci/Dockerfile
  when: manual
  script:
    - claude_ci merge
  only:
    - main
```

- The `claude_ci` wrapper calls the CLI with the appropriate sub‑command.
- Each stage can be overridden by adding an alias in the CLI (`claude ci <stage>`).

---

## 8. CLI Skeleton (Python + Typer)

```python
# cli/main.py
import typer
import os
from .prompts import load_prompt
from .. import claude_api, gitlab_api, utils

app = typer.Typer(help="GitLab + Claude DevOps Assistant")

@app.command()
def init():
    """Create .claude.yaml and set up the repo."""
    utils.create_default_config()
    typer.echo("✅ Initialized .claude.yaml")

@app.command()
def create(user_input: str):
    """Interactively create an issue."""
    prompt = load_prompt("issue_create.md")
    response = claude_api.send(prompt.format(
        project_name=utils.project_name(),
        user_input=user_input,
        default_assignee=utils.default_assignee()
    ))
    issue = utils.parse_json(response)
    gitlab_api.create_issue(issue)
    typer.echo(f"Issue #{issue['iid']} created")

@app.command()
def link_commit(sha: str):
    """Link a commit to the most relevant open issue."""
    commit = gitlab_api.get_commit(sha)
    prompt = load_prompt("commit_link.md")
    response = claude_api.send(prompt.format(
        commit_message=commit.message,
        sha=sha
    ))
    data = utils.parse_json(response)
    if "issue_id" in data:
        gitlab_api.add_issue_comment(data["issue_id"],
            f"Linked by commit {sha}: {data['comment']}")
    else:
        gitlab_api.create_issue({"title": data["suggestion_title"]})
    typer.echo("✅ Commit linked")

# Add more commands here...

if __name__ == "__main__":
    app()
```

- The CLI is intentionally lightweight; all heavy lifting is done by the Claude wrapper and GitLab API.

---

## 9. Testing Strategy

| Layer       | Tool                                      | Focus                                                                                                                                |
| ----------- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Unit        | `pytest`                                  | CLI command parsing, prompt rendering, response parsing.                                                                             |
| Integration | `unittest.mock` + `python-gitlab` sandbox | Test GitLab API interactions without hitting the real API.                                                                           |
| E2E         | Docker Compose                            | Spin up a local GitLab instance (or use GitLab CE), run `claude init`, push a commit, run pipeline, and assert board & issue states. |
| Performance | Locust                                    | Simulate multiple users issuing commands to gauge latency.                                                                           |

---

## 10. Security & Compliance

1. **No secrets in logs** – All outputs from Claude are redacted unless explicitly requested.
2. **Token rotation** – GitLab OAuth tokens are refreshed automatically; only short‑lived tokens are stored.
3. **Rate limiting** – The Claude wrapper enforces a per‑repo quota; excessive usage triggers a warning.
4. **Audit trail** – Every CLI command is logged with timestamp, user, and resulting GitLab event.
5. **Open‑source LLM** – Optionally deploy a self‑hosted Claude clone (e.g., Llama 3) behind a firewall for privacy‑constrained teams.

---

## 11. Future Enhancements (Roadmap)

| Milestone              | Description                                                     | ETA     |
| ---------------------- | --------------------------------------------------------------- | ------- |
| **GraphQL sync**       | Use GitLab GraphQL for bulk data pulls (issues, boards).        | Q4 2026 |
| **Multi‑repo support** | Manage several projects from a single CLI session.              | Q1 2027 |
| **Web UI**             | A lightweight dashboard built with FastAPI + React.             | Q3 2026 |
| **Fine‑tuning**        | Train a Claude‑style model on the repo’s past issues & commits. | Q2 2027 |
| **Marketplace**        | Publish as a GitLab App (installable via UI).                   | Q1 2027 |

---

## 12. Quick‑Start Checklist

1. **Install prerequisites** – Python 3.10+, Docker, GitLab personal access token.
2. **Clone repo** and run `claude init`.
3. **Run a local CI job**: `docker run -e GITLAB_TOKEN=… -e CLAUDE_TOKEN=… gitlab-claude-assistant:latest claude_ci lint`.
4. **Create an issue**: `claude create "Add password reset flow"` – watch as the issue gets auto‑filled and labelled.
5. **Commit**: `git commit -m "Add password reset flow #123"`.
6. **Push & let the CI pipeline finish**.
