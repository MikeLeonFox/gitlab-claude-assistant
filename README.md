# GitLab Workflow — Claude Code Plugin

Automate your GitLab project management from inside Claude Code. Comment on issues, transition their state, reference them in commits, and open merge requests — using plain language or slash commands.

Comments post under your own GitLab account, written in your voice. Claude never announces itself.

---

## Requirements

- [Claude Code](https://claude.ai/code) installed
- [`glab`](https://gitlab.com/gitlab-org/cli) CLI installed and authenticated

```bash
# macOS
brew install glab

# Linux
curl -sL https://github.com/cli/cli/releases/latest | ... # see glab docs

# Authenticate
glab auth login
```

Verify it works:

```bash
glab auth status
# Should show: Logged in to gitlab.example.com as yourname
```

---

## Installation

### From a git URL (recommended)

```bash
claude plugin add git:https://gitlab.example.com/your-group/claude-code-gitlab-skill.git
```

### Local install (for development or testing)

```bash
claude --plugin-dir /path/to/claude-code-gitlab-skill
```

After installing, enable the plugin in Claude Code settings if it isn't automatically enabled.

---

## Quick Start

Once installed, just talk to Claude. The skill activates automatically:

```
"Comment on issue #42 that I'm starting work on this"
"Move issue 12 to in-progress and assign it to me"
"Create a commit that closes issue 55"
"Open a merge request for issue 42"
"I'm blocked on issue 88, add a note saying I'm waiting for design sign-off"
```

Or use the slash commands for explicit, step-by-step control.

---

## Slash Commands

### `/gitlab-issue <id-or-url> [action]`

Manage a GitLab issue end-to-end.

**Actions:**

| Action | What happens |
|--------|-------------|
| `view` | Show issue details and comments *(default)* |
| `comment` | Post a comment as you |
| `start` | Assign to you, label as in-progress, post a start comment, create a branch |
| `finish` | Commit, push, open MR, transition to review, post a comment |
| `move` | Transition the issue to a different label/state |

**Examples:**

```
/gitlab-issue 42
/gitlab-issue 42 start
/gitlab-issue 42 comment
/gitlab-issue 42 finish
/gitlab-issue 42 move

# Full URL works too — project is parsed automatically
/gitlab-issue https://gitlab.example.com/group/project/-/issues/42 start
```

---

### `/gitlab-commit <id-or-url> [closes|relates]`

Create a properly formatted conventional commit that references a GitLab issue.

```
/gitlab-commit 42             # Closes #42 (default)
/gitlab-commit 42 relates     # Related to #42 (no auto-close)
/gitlab-commit https://gitlab.example.com/group/project/-/issues/42
```

Claude will:
1. Check what's staged
2. Ask for commit type and description if needed
3. Write the commit message in conventional format
4. Offer to push and open an MR

---

## Cross-Project Issues

Your issues often live in a different GitLab project than the code you're working in. The plugin resolves the right project automatically:

| Priority | Source | How to use |
|----------|--------|------------|
| 1 | URL passed directly | Paste any GitLab URL when Claude asks |
| 2 | `GITLAB_ISSUE_PROJECT` env var | `export GITLAB_ISSUE_PROJECT=https://.../-/boards` |
| 3 | `.gitlab-workflow` config file | Paste your board URL in a file at your repo root |
| 4 | Git remote `origin` | Automatic when working in the issue project itself |
| 5 | Prompt | Claude asks once and offers to save your answer |

### Setting up `.gitlab-workflow`

Open your GitLab issue board, copy the URL from the browser, and paste it into the file:

```bash
echo "https://gitlab.example.com/group/project/-/boards" > .gitlab-workflow
echo ".gitlab-workflow" >> .gitignore
```

Any URL from the project works — board, issue list, a specific issue, the project root. The plugin extracts the project path automatically. The file is discovered by walking up the directory tree, so one file at a monorepo root covers all sub-projects within it.

---

## How Comments Work

Comments are posted via `glab` under your authenticated GitLab account — they appear as **you**, not as Claude.

Claude writes comments in first person in your voice and confirms the wording with you before posting. It will never add "Claude:", "AI:", or any indication that the comment was generated.

```
You say:    "comment that I'm blocked waiting for the API spec"
Posted as:  "Blocked — waiting for the API spec to be finalised."

You say:    "say the fix is in MR !23"
Posted as:  "Fix is up in !23 for review."
```

---

## Commit Format

The plugin uses [Conventional Commits](https://www.conventionalcommits.org/) with GitLab auto-close keywords:

```
feat(auth): add password reset flow

Closes #42
```

**Types:** `feat` `fix` `docs` `style` `refactor` `perf` `test` `chore` `ci`

**Auto-close keywords** *(take effect when the MR merges to the default branch):*
`Closes` `Fixes` `Resolves` `Implements`

**Reference without closing:**
`Related to` `Part of` `See`

**Cross-project reference:**
```
Closes group/project#42
```

---

## Plugin Structure

```
claude-code-gitlab-skill/
├── .claude-plugin/
│   └── plugin.json                              # Plugin manifest
├── skills/
│   └── gitlab-workflow/
│       ├── SKILL.md                             # Auto-activating skill
│       ├── scripts/
│       │   └── resolve-project.sh              # Project path resolution logic
│       └── references/
│           ├── glab-commands.md                # Full glab flag reference
│           ├── commit-conventions.md           # Commit format + GitLab keywords
│           └── config-guide.md                 # .gitlab-workflow config docs
└── commands/
    ├── gitlab-issue.md                          # /gitlab-issue slash command
    └── gitlab-commit.md                         # /gitlab-commit slash command
```

The skill auto-activates based on context — no slash command needed for everyday use. The slash commands give you explicit, structured control when you want it.

---

## Troubleshooting

**`glab: command not found`**
Install glab: `brew install glab` (macOS) or see [glab installation docs](https://gitlab.com/gitlab-org/cli#installation).

**Comments posting as the wrong user**
Run `glab auth status` to check which account is active. Switch with `glab auth login`.

**Wrong project being targeted**
Paste the full issue URL, or create a `.gitlab-workflow` file with `issue_project=group/project`.

**`ERROR: 404 Not Found`**
Check that your glab token has access to the target project. Verify the project path with `glab repo view -R group/project`.

**`glab auth login` for a self-hosted GitLab instance**
```bash
glab auth login --hostname gitlab.yourcompany.com
```

---

## License

MIT
