# Commit Conventions with GitLab Issue References

## Format

```
<type>(<optional scope>): <description>

<optional body>

<optional footer>
```

## Types

| Type | Use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Neither fix nor feature |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `chore` | Build, tooling, CI |
| `ci` | CI/CD config |
| `revert` | Reverts a previous commit |

Description rules: imperative mood, lowercase, no period, ≤72 chars.

## GitLab Keywords

**Auto-close on merge to default branch:**
```
Closes #42
Fixes #42
Resolves #42
Implements #42
```

**Reference only:**
```
Related to #42
Part of #42
Refs #42
```

**Multiple / cross-project:**
```
Closes #42, #57
Closes group/project#42
```

## Examples

```
feat(auth): add OAuth2 login support

Closes #42
```

```
fix(api): handle null response from user endpoint

Fixes #87
Related to #91
```

```
chore: update dependencies
```

## Branch Naming

```
feat/issue-42-oauth-login
fix/issue-87-null-user-response
```

Pattern: `<type>/issue-<id>-<short-description>`

## Notes

- Closing keywords in MR descriptions also work
- Issue closes only when commit lands on the **default branch**
