#!/bin/bash
set -e

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Error: Platform version argument is required"
    echo "Usage: $0 <platform-version>"
    exit 1
fi

# Set environment variables
PLATFORM_VERSION=$1
BRANCH_NAME="platform-$PLATFORM_VERSION"
RELEASE_VERSION=$(echo "$PLATFORM_VERSION" | tr '-' '.')

# Commit and push changes
echo "Attempting to commit and push changes to branch ${BRANCH_NAME}..."

echo "Changes detected. Proceeding with commit and push."
git add charts/platform/*
git commit -s -m "chore(release): Update platform charts for ${RELEASE_VERSION}" --no-verify || \
  echo "No changes to commit."
git push origin "${BRANCH_NAME}"

echo "Successfully pushed to branch ${BRANCH_NAME}."
