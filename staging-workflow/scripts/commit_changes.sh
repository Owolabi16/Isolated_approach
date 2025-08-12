#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Error: Platform version argument is required"
  echo "Usage: $0 <platform-version>"
  exit 1
fi

INPUT_VERSION="$1"
BRANCH_NAME="platform-$INPUT_VERSION"
RELEASE_VERSION="${INPUT_VERSION//-/.}"

if git rev-parse --verify "${BRANCH_NAME}" >/dev/null 2>&1; then
  echo "Checking out existing branch ${BRANCH_NAME}..."
  git checkout "${BRANCH_NAME}"
else
  echo "Creating and checking out new branch ${BRANCH_NAME}..."
  git checkout -b "${BRANCH_NAME}"
fi

echo "Attempting to commit and push changes to branch ${BRANCH_NAME}..."

git add charts/platform/*
COMMIT_PREFIX="${COMMIT_PREFIX:-chore:}"
git commit -s -m "${COMMIT_PREFIX} Update platform charts for ${RELEASE_VERSION}" --no-verify || echo "No changes to commit."

if git ls-remote --exit-code --heads origin "${BRANCH_NAME}" > /dev/null; then
  echo "Remote branch ${BRANCH_NAME} exists. Fetching and rebasing..."
  git fetch origin "${BRANCH_NAME}"
  git rebase origin/"${BRANCH_NAME}" || git rebase --abort
else
  echo "Remote branch ${BRANCH_NAME} does NOT exist. Skipping fetch/rebase."
fi

git push -u origin "${BRANCH_NAME}"

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
