#!/usr/bin/env bash
# fix-issue-labels-and-epic.sh
# Normalizes a GitLab issue's labels and epic to match patterns from sibling issues.
#
# - Detects most common namespaced label per namespace (project::X, status::X, etc.)
# - Applies missing namespace labels to the target issue
# - Removes orphan labels (non-namespaced and absent from all sibling issues)
# - Links the most common epic if siblings share one and the target doesn't
# - Prints a summary of all changes made
#
# Usage:
#   bash scripts/fix-issue-labels-and-epic.sh <issue_iid>

set -uo pipefail

ISSUE_IID="${1:?Usage: fix-issue-labels-and-epic.sh <issue_iid>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Resolve host + project
GITLAB_HOST=$(bash "$SCRIPT_DIR/resolve-host.sh")
export GITLAB_HOST
PROJECT=$(bash "$SCRIPT_DIR/resolve-project.sh")

echo "Analyzing: $PROJECT #$ISSUE_IID"

# 2. Fetch all open issues (up to 100)
ALL_ISSUES=$(glab issue list -R "$PROJECT" --output json --per-page 100 2>/dev/null || echo "[]")

if [[ "$ALL_ISSUES" == "[]" || -z "$ALL_ISSUES" ]]; then
  echo "No open issues found in $PROJECT."
  exit 0
fi

# Verify target issue is in the open list
TARGET_COUNT=$(echo "$ALL_ISSUES" | jq --argjson iid "$ISSUE_IID" '[.[] | select(.iid == $iid)] | length')
if [[ "$TARGET_COUNT" == "0" ]]; then
  echo "Issue #$ISSUE_IID not found among open issues. It may be closed or the iid is wrong."
  exit 1
fi

# 3. Gather labels
TARGET_LABELS=$(echo "$ALL_ISSUES" | jq -r --argjson iid "$ISSUE_IID" \
  '.[] | select(.iid == $iid) | .labels[]' 2>/dev/null || true)

SIBLING_LABELS=$(echo "$ALL_ISSUES" | jq -r --argjson iid "$ISSUE_IID" \
  '.[] | select(.iid != $iid) | .labels[]' 2>/dev/null || true)

# 4. Find most common namespaced label per namespace from siblings
# uniq -c counts, sort -rn puts most frequent first, awk picks first per namespace
BEST_LABELS=""
if [[ -n "$SIBLING_LABELS" ]]; then
  BEST_LABELS=$(echo "$SIBLING_LABELS" | grep '::' 2>/dev/null | sort | uniq -c | sort -rn | \
    awk '{
      split($2, a, "::")
      ns = a[1]
      if (!(ns in seen)) { seen[ns] = 1; print $2 }
    }' || true)
fi

# Namespaces the target already has (one per line)
TARGET_NS=$(echo "$TARGET_LABELS" | grep '::' 2>/dev/null | sed 's/::.*$//' || true)

# Labels to add: best-per-namespace where target is missing that namespace
LABELS_TO_ADD=()
if [[ -n "$BEST_LABELS" ]]; then
  while IFS= read -r best_label; do
    [[ -z "$best_label" ]] && continue
    ns="${best_label%%::*}"
    if ! echo "$TARGET_NS" | grep -qx "$ns" 2>/dev/null; then
      LABELS_TO_ADD+=("$best_label")
    fi
  done <<< "$BEST_LABELS"
fi

# Orphan labels to remove: non-namespaced labels on target not present on any sibling
LABELS_TO_REMOVE=()
if [[ -n "$TARGET_LABELS" ]]; then
  while IFS= read -r label; do
    [[ -z "$label" ]] && continue
    [[ "$label" == *::* ]] && continue  # keep namespaced labels
    if [[ -z "$SIBLING_LABELS" ]] || ! echo "$SIBLING_LABELS" | grep -qx "$label" 2>/dev/null; then
      LABELS_TO_REMOVE+=("$label")
    fi
  done <<< "$TARGET_LABELS"
fi

# 5. Apply label changes
if [[ ${#LABELS_TO_ADD[@]} -gt 0 || ${#LABELS_TO_REMOVE[@]} -gt 0 ]]; then
  UPDATE_ARGS=()
  for l in "${LABELS_TO_ADD[@]}";   do UPDATE_ARGS+=("--label"   "$l"); done
  for l in "${LABELS_TO_REMOVE[@]}"; do UPDATE_ARGS+=("--unlabel" "$l"); done
  glab issue update "$ISSUE_IID" -R "$PROJECT" "${UPDATE_ARGS[@]}"
fi

# 6. Detect and apply parent epic
MOST_COMMON_EPIC=$(echo "$ALL_ISSUES" | jq --argjson iid "$ISSUE_IID" '
  [.[] | select(.iid != $iid) | .epic_iid | select(. != null)]
  | if length == 0 then empty
    else group_by(.) | sort_by(-length) | .[0][0]
    end
' 2>/dev/null || true)

TARGET_EPIC=$(echo "$ALL_ISSUES" | jq --argjson iid "$ISSUE_IID" \
  '.[] | select(.iid == $iid) | .epic_iid // empty' 2>/dev/null || true)

EPIC_LINKED=false
if [[ -n "$MOST_COMMON_EPIC" && "$TARGET_EPIC" != "$MOST_COMMON_EPIC" ]]; then
  GROUP_PATH="${PROJECT%/*}"
  if [[ "$GROUP_PATH" == "$PROJECT" ]]; then
    echo "Warning: Cannot link epic — project has no parent group."
  else
    PROJECT_ENCODED=$(echo "$PROJECT" | sed 's|/|%2F|g')
    PROJECT_ID=$(glab api "projects/$PROJECT_ENCODED" | jq '.id')
    GROUP_ENCODED=$(echo "$GROUP_PATH" | sed 's|/|%2F|g')
    EPIC_GLOBAL_ID=$(glab api "groups/$GROUP_ENCODED/epics/$MOST_COMMON_EPIC" | jq '.id')
    glab api --method PUT "projects/$PROJECT_ID/issues/$ISSUE_IID" \
      -f "epic_id=$EPIC_GLOBAL_ID" > /dev/null
    EPIC_LINKED=true
  fi
fi

# 7. Report
echo ""
echo "=== Fix Summary: #$ISSUE_IID in $PROJECT ==="
if [[ ${#LABELS_TO_ADD[@]} -gt 0 ]]; then
  printf "Labels added:   %s\n" "${LABELS_TO_ADD[*]}"
else
  echo "Labels added:   (none)"
fi
if [[ ${#LABELS_TO_REMOVE[@]} -gt 0 ]]; then
  printf "Labels removed: %s\n" "${LABELS_TO_REMOVE[*]}"
else
  echo "Labels removed: (none)"
fi
if [[ "$EPIC_LINKED" == true ]]; then
  echo "Epic linked:    epic!$MOST_COMMON_EPIC"
else
  echo "Epic linked:    (no change)"
fi
