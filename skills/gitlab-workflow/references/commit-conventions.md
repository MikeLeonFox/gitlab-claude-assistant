# Commit Conventions with GitLab Issue References

## Conventional Commits Format

```
<type>(<optional scope>): <short description>

<optional body>

<optional footer with GitLab references>
```

### Types

| Type       | Use case                                         |
|------------|--------------------------------------------------|
| `feat`     | New feature                                      |
| `fix`      | Bug fix                                          |
| `docs`     | Documentation only                               |
| `style`    | Formatting, no logic change                      |
| `refactor` | Code change that's neither fix nor feature       |
| `perf`     | Performance improvement                          |
| `test`     | Adding or fixing tests                           |
| `chore`    | Build process, tooling, CI changes               |
| `ci`       | CI/CD config changes                             |
| `revert`   | Reverts a previous commit                        |

### Short Description Rules
- Imperative mood: "add feature" not "added feature"
- No capital letter at start
- No period at end
- Max ~72 characters

---

## GitLab Magic Keywords

These keywords in a commit message (or MR description) **automatically close** the referenced issue when the MR is merged into the default branch.

### Closing keywords (case-insensitive)
```
Closes #<id>
Fixes #<id>
Resolves #<id>
Implements #<id>
```

### Reference only (no auto-close)
```
Related to #<id>
See #<id>
Part of #<id>
Refs #<id>
```

### Multiple issues
```
Closes #42, #57
Fixes #38 and #39
```

### Cross-project references
```
Closes group/project#42
```

---

## Examples

### Feature commit closing one issue
```
feat(auth): add OAuth2 login support

Implements JWT token refresh logic and integrates
with the company SSO provider.

Closes #42
```

### Bug fix referencing multiple issues
```
fix(api): handle null response from user endpoint

The user endpoint returns null when no record is found.
Added null check and proper 404 response.

Fixes #87
Related to #91
```

### Chore with no issue link
```
chore: update dependencies to latest patch versions
```

### Work-in-progress commit (doesn't close issue)
```
feat(dashboard): add chart component (WIP)

Related to #55
```

### Merge commit format (auto-generated or manual)
```
Merge branch 'feat/issue-42-oauth-login' into 'main'

feat(auth): add OAuth2 login support

Closes #42

See merge request group/project!23
```

---

## Branch Naming Conventions

Use the issue number in the branch name for traceability:

```
feat/issue-42-oauth-login
fix/issue-87-null-user-response
chore/issue-12-update-deps
docs/issue-33-api-docs
```

Pattern: `<type>/issue-<id>-<short-description>`

GitLab also supports creating branches directly from an issue via the UI (creates `<id>-issue-title` format).

---

## GitLab-Specific Patterns

### Closing MR via commit
GitLab closes the issue when the commit lands on the **default branch** (usually `main`/`master`). Merging into feature branches does NOT close issues.

### MR description keywords
The same closing keywords work in MR descriptions:
```markdown
## What does this MR do?
Adds OAuth2 login.

Closes #42
```

### Commit message for a hotfix
```
fix(auth): prevent session token leakage on logout

Clears all session cookies and invalidates server-side token
on explicit logout action.

Fixes #103
```
