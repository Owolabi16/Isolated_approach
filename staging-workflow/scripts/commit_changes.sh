#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Error: Platform version argument is required"
  echo "Usage: $0 <platform-version>"
  exit 1
fi

PLATFORM_VERSION=$1
RELEASE_VERSION=$(echo "$PLATFORM_VERSION" | tr '-' '.')
RELEASE_TYPE="${RELEASE_TYPE:-minor}"
COMMIT_PREFIX="${COMMIT_PREFIX:-chore:}"

# Determine target branch
if [ "$RELEASE_TYPE" = "patch" ]; then
    # For patch, use default branch
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    echo "Patch release - committing to $BRANCH_NAME"
else
    # For minor, use platform branch
    BRANCH_NAME="platform-$PLATFORM_VERSION"
    echo "Minor release - creating/using $BRANCH_NAME"
    
    # Create and checkout branch only for minor releases
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "Local branch $BRANCH_NAME exists. Checking out..."
        git checkout "$BRANCH_NAME"
    else
        echo "Creating and checking out new branch $BRANCH_NAME..."
        git checkout -b "$BRANCH_NAME"
    fi
fi

echo "Attempting to commit and push changes to branch ${BRANCH_NAME}..."

git add charts/platform/*
git commit -s -m "${COMMIT_PREFIX} Update platform charts for ${RELEASE_VERSION}" --no-verify || \
  echo "No changes to commit."

if [ "$RELEASE_TYPE" = "patch" ]; then
    # For patch, push to current branch (should be main)
    git push origin HEAD
else
    # For minor, push to platform branch
    git push origin "${BRANCH_NAME}"
fi

echo "Successfully pushed to branch ${BRANCH_NAME}."


# #!/bin/bash
# set -e

# # Check if argument is provided
# if [ -z "$1" ]; then
#     echo "Error: Platform version argument is required"
#     echo "Usage: $0 <platform-version>"
#     exit 1
# fi

# # Extract version from input
# INPUT_VERSION="$1"

# # Branch name should keep the original hyphen style
# BRANCH_NAME="platform-$INPUT_VERSION"

# # Release version should replace hyphens with dots
# RELEASE_VERSION="${INPUT_VERSION//-/.}"

# # Checkout branch before making changes
# if git rev-parse --verify "${BRANCH_NAME}" >/dev/null 2>&1; then
#     echo "Checking out existing branch ${BRANCH_NAME}..."
#     git checkout "${BRANCH_NAME}"
# else
#     echo "Creating and checking out new branch ${BRANCH_NAME}..."
#     git checkout -b "${BRANCH_NAME}"
# fi

# # Commit and push changes
# echo "Attempting to commit and push changes to branch ${BRANCH_NAME}..."

# git add charts/platform/*
# COMMIT_PREFIX="${COMMIT_PREFIX:-chore:}"
# git commit -s -m "${COMMIT_PREFIX} Update platform charts for ${RELEASE_VERSION}" --no-verify || \
#   echo "No changes to commit."

# # Sync with remote before pushing
# git fetch origin "${BRANCH_NAME}"
# git rebase origin/"${BRANCH_NAME}" || git rebase --abort

# git push origin -u "${BRANCH_NAME}"

# echo "Successfully pushed to branch ${BRANCH_NAME}."
