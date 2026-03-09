#!/usr/bin/env bash
# resolve-project.sh
# Resolves the GitLab project path (-R value) for glab commands.
#
# Priority order:
#   1. Argument passed directly: resolve-project.sh "https://.../-/boards" or "group/project"
#   2. GITLAB_ISSUE_PROJECT environment variable (URL or path)
#   3. .gitlab-workflow config file (nearest, walking up from CWD)
#      — contains a pasted GitLab URL (board, issue, project, MR, etc.)
#   4. Current git remote origin (if it's a GitLab remote)
#   5. Exits with error — caller must ask the user
#
# .gitlab-workflow format — just paste any GitLab URL on the first line:
#   https://gitlab.example.com/group/project/-/boards
#
# Usage:
#   PROJECT=$(bash resolve-project.sh [url-or-path])
#   glab issue note 42 -R "$PROJECT" -m "comment"

set -e

# --- Helper: extract project path from any GitLab URL ---
# Works with boards, issues, MRs, pipelines, the project root, git remotes, etc.
# Input:  https://gitlab.example.com/group/subgroup/project/-/boards/1
# Output: group/subgroup/project
parse_gitlab_url() {
  local url="$1"
  echo "$url" \
    | sed -E 's|https?://[^/]+/||' \
    | sed -E 's|/-/.*||' \
    | sed -E 's|\.git$||' \
    | tr -d '[:space:]'
}

# --- Helper: extract project path from git remote ---
git_remote_project() {
  local remote
  remote=$(git remote get-url origin 2>/dev/null) || return 1
  case "$remote" in
    https://*)
      parse_gitlab_url "$remote"
      ;;
    git@*)
      # git@gitlab.example.com:group/project.git → group/project
      echo "$remote" | sed -E 's|git@[^:]+:||' | sed -E 's|\.git$||'
      ;;
    *)
      return 1
      ;;
  esac
}

# --- Helper: find .gitlab-workflow config walking up directories ---
find_config() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.gitlab-workflow" ]]; then
      echo "$dir/.gitlab-workflow"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Read the first non-empty, non-comment line from .gitlab-workflow
# and parse it as a GitLab URL or project path.
read_config_project() {
  local config_file value
  config_file=$(find_config) || return 1
  # Skip blank lines and lines starting with #
  value=$(grep -v -E '^\s*(#|$)' "$config_file" | head -1 | tr -d '[:space:]')
  [[ -z "$value" ]] && return 1
  if [[ "$value" =~ ^https?:// ]]; then
    parse_gitlab_url "$value"
  else
    echo "$value"
  fi
}

# --- Main resolution ---

ARG="${1:-}"

# 1. Direct argument — URL or path
if [[ -n "$ARG" ]]; then
  if [[ "$ARG" =~ ^https?:// ]]; then
    parse_gitlab_url "$ARG"
  else
    echo "$ARG"
  fi
  exit 0
fi

# 2. Environment variable — URL or path
if [[ -n "${GITLAB_ISSUE_PROJECT:-}" ]]; then
  if [[ "$GITLAB_ISSUE_PROJECT" =~ ^https?:// ]]; then
    parse_gitlab_url "$GITLAB_ISSUE_PROJECT"
  else
    echo "$GITLAB_ISSUE_PROJECT"
  fi
  exit 0
fi

# 3. .gitlab-workflow config file
if project=$(read_config_project 2>/dev/null) && [[ -n "$project" ]]; then
  echo "$project"
  exit 0
fi

# 4. Git remote origin
if project=$(git_remote_project 2>/dev/null) && [[ -n "$project" ]]; then
  echo "$project"
  exit 0
fi

# 5. Nothing found
exit 1
