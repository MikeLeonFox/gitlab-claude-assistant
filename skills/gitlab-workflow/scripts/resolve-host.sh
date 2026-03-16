#!/usr/bin/env bash
# resolve-host.sh
# Resolves the GitLab hostname for use as GITLAB_HOST.
#
# Priority order:
#   1. .gitlab-workflow.json url field (nearest, walking up from CWD)
#   2. GITLAB_HOST environment variable
#   3. Git remote origin (skips github/bitbucket)
#   4. glab auth status (first non-gitlab.com host)
#   5. Falls back to gitlab.com
#
# Usage:
#   GITLAB_HOST=$(bash resolve-host.sh)
#   export GITLAB_HOST  # glab picks it up automatically

# 1. .gitlab-workflow.json
root=$(git rev-parse --show-toplevel 2>/dev/null) || true
if [[ -n "$root" && -f "$root/.gitlab-workflow.json" ]]; then
  h=$(jq -r '.url // empty' "$root/.gitlab-workflow.json" 2>/dev/null \
    | sed -E 's|https?://([^/]+)/.*|\1|' \
    | grep -v '^$' || true)
  [[ -n "$h" ]] && echo "$h" && exit 0
fi

# 2. GITLAB_HOST env var
[[ -n "${GITLAB_HOST:-}" ]] && echo "$GITLAB_HOST" && exit 0

# 3. Git remote origin
remote=$(git remote get-url origin 2>/dev/null) || true
if [[ -n "$remote" ]]; then
  h=$(echo "$remote" | sed -E 's|https?://([^/]+)/.*|\1|; s|git@([^:]+):.*|\1|')
  if echo "$h" | grep -Eqv 'github\.com|bitbucket\.org' 2>/dev/null; then
    echo "$h" && exit 0
  fi
fi

# 4. glab auth (first self-hosted)
h=$(glab auth status 2>&1 \
  | grep -E 'Logged in to' \
  | grep -v 'gitlab\.com' \
  | sed -E 's/.*Logged in to ([^ ]+).*/\1/' \
  | head -1 || true)
[[ -n "$h" ]] && echo "$h" && exit 0

# 5. Default
echo "gitlab.com"
