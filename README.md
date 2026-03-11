# GitLab Workflow Skill for Claude Code

Automates GitLab issue management, merge requests, CI/CD monitoring, and commit workflows using the [`glab`](https://gitlab.com/gitlab-org/cli) CLI.

## Prerequisites

Install and authenticate `glab`:

```bash
brew install glab   # macOS — see https://gitlab.com/gitlab-org/cli for other platforms
glab auth login
```

## Installation

In Claude Code:

```
/plugin marketplace add MikeLeonFox/gitlab-claude-assistant
/plugin install gitlab-workflow@claude-gitlab-skill
```

## Usage

The skill activates automatically when you mention GitLab operations in plain language:

```
Start working on issue #42
Finish issue 15 and open an MR
Comment on #8 saying I'm blocked waiting for design
Check the CI pipeline status
```

You can also invoke commands directly:

| Command | Description |
|---|---|
| `/gitlab-workflow:gitlab-issue 42 view` | View issue #42 with comments |
| `/gitlab-workflow:gitlab-issue 42 start` | Assign, label, comment, create branch |
| `/gitlab-workflow:gitlab-issue 42 finish` | Commit, push, open MR, update labels |
| `/gitlab-workflow:gitlab-issue 42 comment` | Post a comment as you |
| `/gitlab-workflow:gitlab-issue 42 move` | Transition workflow labels |
| `/gitlab-workflow:gitlab-commit 42` | Conventional commit that closes #42 |
| `/gitlab-workflow:gitlab-commit 42 relates` | Commit that references (not closes) #42 |

## Configuration

If your issue board is in a different project than the code you're working in, create a `.gitlab-workflow.json` file at your repo root:

```json
{
  "url": "https://gitlab.example.com/your-group/your-project/-/boards"
}
```

```bash
echo ".gitlab-workflow.json" >> .gitignore
```

Any GitLab URL from the project works — board, issue list, a specific issue, MR, or the project root. You only need to set this up once. A single file at a monorepo root covers all sub-projects beneath it.

The plugin resolves the project in this order:

1. URL passed directly in your message
2. `GITLAB_ISSUE_PROJECT` environment variable
3. `.gitlab-workflow.json` file (walks up from current directory)
4. Git remote `origin` (if it's a GitLab remote)
5. Asks you

## License

MIT
