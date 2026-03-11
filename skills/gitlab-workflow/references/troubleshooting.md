# glab Troubleshooting Guide

Comprehensive troubleshooting guide for common glab CLI issues and errors.

## Installation Issues

### Command Not Found

**Error:**
```
command not found: glab
```

**Solutions:**
1. Verify installation: `which glab`
2. Install glab if missing:
   - macOS: `brew install glab`
   - Linux: see https://gitlab.com/gitlab-org/cli/-/releases
3. If installed but not in PATH, add to `~/.zshrc` or `~/.bashrc`:
   ```bash
   export PATH="$PATH:/path/to/glab"
   ```

### Version Conflicts

**Solution:** Update to the latest version:
```bash
# macOS
brew upgrade glab

# Linux
sudo apt update && sudo apt upgrade glab
```

---

## Authentication Issues

### 401 Unauthorized

**Error:**
```
failed to get current user: GET https://gitlab.com/api/v4/user: 401 {message: 401 Unauthorized}
```

**Solutions:**
1. Authenticate: `glab auth login`
2. Check status: `glab auth status`
3. Re-authenticate with token:
   ```bash
   glab auth login --hostname gitlab.com --token YOUR_TOKEN
   ```
4. Verify token has correct scopes: `api`, `read_user`, `write_repository`
5. For self-hosted GitLab:
   ```bash
   glab auth login --hostname gitlab.example.org
   ```

### 403 Forbidden / Insufficient Permissions

**Causes:** Token lacks required scopes, or user doesn't have project access.

**Solutions:**
1. Create a new token with scopes: `api`, `read_api`, `read_user`, `write_repository`, `read_repository`
2. Verify project access in the GitLab web UI
3. Check if project is private and token has access

### Multiple Accounts / Self-Hosted

```bash
# Authenticate with both
glab auth login --hostname gitlab.com
glab auth login --hostname gitlab.example.org

# Check all authenticated accounts
glab auth status

# Use specific host for a command
glab mr list -R gitlab.example.org/namespace/project
```

---

## Repository Context Issues

### Not a Git Repository

**Error:**
```
fatal: not a git repository (or any of the parent directories): .git
```

**Solutions:**
1. Navigate to a Git repository: `cd /path/to/your/repo`
2. Or specify repository explicitly: `glab mr list -R owner/repo`

### Wrong Repository Detected

**Solutions:**
1. Check current repository remote: `git remote -v`
2. Specify correct repository: `glab mr list -R owner/correct-repo`
3. Update remote if wrong:
   ```bash
   git remote set-url origin git@gitlab.com:owner/correct-repo.git
   ```

### 404 Project Not Found

**Causes:** Repository doesn't exist, wrong namespace, no access, wrong GitLab instance.

**Solutions:**
1. Verify repository name and namespace (format: `namespace/project`)
2. Check you have access in the GitLab web UI
3. Verify GitLab instance: `glab auth status`
4. For self-hosted:
   ```bash
   GITLAB_HOST=gitlab.example.org glab repo view
   ```

---

## Merge Request Issues

### Source Branch Already Has MR

**Error:**
```
failed to create merge request: source branch already has a merge request
```

**Solutions:**
1. List existing MRs:
   ```bash
   glab mr list
   glab mr list --source-branch=$(git branch --show-current)
   ```
2. Update existing MR instead:
   ```bash
   glab mr update <mr-number> --title "New title"
   ```

### Cannot Merge: Conflicts Exist

**Solutions:**
1. Checkout MR locally: `glab mr checkout <mr-number>`
2. Fetch latest target branch: `git fetch origin main`
3. Merge or rebase:
   ```bash
   git merge origin/main
   # or
   git rebase origin/main
   ```
4. Resolve conflicts, commit, and push

### Pipeline Must Succeed

**Error:**
```
cannot merge: pipeline must succeed
```

**Solutions:**
1. Check status: `glab ci status`
2. View pipeline: `glab pipeline ci view`
3. Fix failures and retry: `glab ci retry`

---

## Pipeline/CI Issues

### Pipeline Not Found

**Solutions:**
1. Trigger a pipeline: `glab ci run`
2. Check if `.gitlab-ci.yml` exists: `ls -la .gitlab-ci.yml`
3. Verify CI/CD is enabled in project settings

### CI Lint Errors

**Error:**
```
.gitlab-ci.yml is invalid
```

**Solutions:**
1. Lint locally: `glab ci lint`
2. Common issues: YAML syntax errors (tabs vs spaces), invalid job names, incorrect indentation

### Cannot Download Artifacts

**Causes:** Artifacts expired, job didn't produce artifacts, permission issues.

**Solutions:**
1. Check job artifacts: `glab ci view <pipeline-id>`
2. Verify artifacts haven't expired (check project settings)
3. Retry job: `glab ci retry`

---

## Network and Connection Issues

### Connection Timeout

**Error:** `dial tcp: i/o timeout`

**Solutions:**
1. Check network: `ping gitlab.com`
2. Verify GitLab status: `curl -I https://gitlab.com`
3. Check firewall/proxy settings

### SSL Certificate Issues

**Error:** `x509: certificate signed by unknown authority`

**Solutions:**
1. Add certificate to system trust store (preferred)
2. Configure Git to use specific CA bundle:
   ```bash
   git config --global http.sslCAInfo /path/to/cert.pem
   ```
3. For development only (NOT production): `export GIT_SSL_NO_VERIFY=true`

---

## Environment Variable Issues

### GITLAB_HOST Not Recognized

**Solutions:**
1. Export in current shell: `export GITLAB_HOST=gitlab.example.org`
2. Add to shell profile permanently:
   ```bash
   echo 'export GITLAB_HOST=gitlab.example.org' >> ~/.zshrc
   source ~/.zshrc
   ```
3. Or use per-command: `glab mr list -R gitlab.example.org/owner/repo`

### GITLAB_TOKEN Not Working

**Solutions:**
1. Verify it's exported: `echo $GITLAB_TOKEN`
2. Ensure no spaces or quotes:
   ```bash
   # Correct
   export GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
   ```
3. Verify token is valid in GitLab web UI

---

## Output and Display Issues

### Garbled or Missing Output

**Solutions:**
1. Disable glamour styling: `export GLAMOUR_STYLE=notty`
2. Use plain text: `glab mr list --output=text`

### JSON Parsing Errors

**Solutions:**
1. Ensure command supports JSON: `glab mr list --output=json`
2. Validate with jq: `glab mr list --output=json | jq '.'`

---

## Performance Issues

### Commands Running Slowly

**Solutions:**
1. Limit results: `glab mr list --per-page=10 --page=1`
2. Use specific filters: `glab mr list --assignee=@me --state=opened`
3. Disable web browser opening: `glab mr view 123 --web=false`

---

## General Troubleshooting Steps

When encountering any error:

1. **Check version:** `glab version`
2. **Update glab:** `glab check-update`
3. **Enable verbose output:** `glab <command> --verbose`
4. **Check authentication:** `glab auth status`
5. **Verify repository context:** `git remote -v`
6. **Use --help:** `glab <command> --help`
7. **Check GitLab status:** https://status.gitlab.com

## Getting Additional Help

- glab documentation: https://docs.gitlab.com/editor_extensions/gitlab_cli/
- glab issues: https://gitlab.com/gitlab-org/cli/-/issues
- When filing an issue, include: glab version, OS, full error message, steps to reproduce, `--verbose` output
