#!/bin/bash
set -eo pipefail

# Validate input format
if [[ -z "$1" || ! "$1" =~ ^[0-9]+-[0-9]+-[0-9]+$ ]]; then
    echo "Error: Version must match pattern: digits-digits-digits (e.g. x-x-x)"
    echo "Usage: $0 <platform-version>"
    exit 1
fi

VERSION="$1"
ORG="alaffia-Technology-Solutions"
REPO="infra"
BRANCH_NAME="platform-$VERSION"

# Check if the platform branch exists in the infra repository
if ! gh api "repos/$ORG/$REPO/branches/$BRANCH_NAME" --silent >/dev/null 2>&1; then
    echo "❌ Platform branch $BRANCH_NAME does not exist in $REPO"
    exit 0
fi

# Get the default branch of the repository
DEFAULT_BRANCH=$(gh repo view "$ORG/$REPO" --json defaultBranchRef -q '.defaultBranchRef.name')

# --- Error Handling for gh pr list ---
# Safely find the relevant open pull request
echo "🔎 Finding open PR from $BRANCH_NAME to $DEFAULT_BRANCH..."
PR_DATA=$(gh pr list --repo "$ORG/$REPO" \
    --head "$BRANCH_NAME" \
    --base "$DEFAULT_BRANCH" \
    --json number,mergeable,state,title \
    --jq 'map(select(.state == "OPEN")) | sort_by(.number) | .[0] // empty' 2>&1)

# Exit if the command failed
if [ $? -ne 0 ]; then
     echo "   ❗ Failed to get PR list for $REPO: $PR_DATA"
     exit 1
fi

# Exit if no open PR was found
if [ -z "$PR_DATA" ]; then
    echo "ℹ️ No open PR found from $BRANCH_NAME to $DEFAULT_BRANCH in $REPO"
    exit 0
fi

PR_NUMBER=$(jq -r '.number' <<< "$PR_DATA")
MERGEABLE=$(jq -r '.mergeable' <<< "$PR_DATA")
TITLE=$(jq -r '.title' <<< "$PR_DATA")

# Check if the pull request is in a mergeable state
if [ "$MERGEABLE" != "MERGEABLE" ]; then
    echo "❌ PR #$PR_NUMBER is not mergeable (Status: ${MERGEABLE:-UNKNOWN})"
    echo "   Title: $TITLE"
    echo "   Please resolve conflicts or check status manually."
    exit 1
fi

echo "✅ Found mergeable PR: #$PR_NUMBER"
echo "   Title: $TITLE"

# --- Retry Logic for Merging ---
# Attempt to merge the pull request up to 3 times
for attempt in {1..3}; do
    echo "🚀 Merging PR #$PR_NUMBER (Attempt $attempt)..."
    if gh pr merge "$PR_NUMBER" --repo "$ORG/$REPO" \
        --squash \
        --delete-branch \
        --body "Automated merge of platform release $VERSION"; then
        echo "✅ Successfully merged PR #$PR_NUMBER in $REPO"
        exit 0 # Exit script successfully
    else
        echo "   ⚠️ Merge attempt $attempt failed."
        if [[ $attempt -eq 3 ]]; then
            echo "   ❌ All merge attempts failed for PR #$PR_NUMBER. Please merge manually."
            exit 1 # Exit with failure
        fi
        sleep $((attempt * 3)) # Wait 3, 6 seconds between attempts
    fi
done
