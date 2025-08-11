#!/bin/bash
set -euo pipefail

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Error: Version argument is required"
    echo "Usage: $0 <version> (format: 1-6-0)"
    exit 1
fi

# Convert version format and validate
CHART_VERSION=$(echo "$1" | tr '-' '.')
if [[ ! "$CHART_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Use X-X-X (e.g. 1-6-0)"
    exit 1
fi

PLATFORM_CHART_PATH="charts/platform/Chart.yaml"
ORG="Alaffia-Technology-Solutions"
REPO="infra"

# Determine which branch to read from based on release type
if [ "$VERSION_SOURCE" = "default" ]; then
    echo "Patch release mode: Reading from default branches"
    BRANCH_REF="default"
else
    echo "Minor release mode: Reading from platform branches"
    BRANCH_REF="platform-$1"
fi


# Update platform chart version
echo "Updating Platform Chart version to $CHART_VERSION"
yq -i ".version = \"$CHART_VERSION\"" "$PLATFORM_CHART_PATH"

# Initialize arrays
DEPENDENCY_NAMES=()
DEPENDENCY_VERSIONS=()

# Helper function to run gh commands and suppress errors
safe_gh() {
    gh "$@" 2>/dev/null || true
}

process_chart() {
    local repo=$1
    local ref=$2
    local path=$3
    local name=$4
    local chart_type=$5

    echo "  Checking ${path%%/*}..."
    
    local chart_content
    chart_content=$(safe_gh api "repos/$ORG/$repo/contents/$path/Chart.yaml?ref=$ref" --jq '.content')
    
    if [ -n "$chart_content" ] && [[ "$chart_content" != *"message"* ]]; then
        local version
        version=$(echo "$chart_content" | base64 --decode 2>/dev/null | awk '/^version:/ {print $2}')
        
        if [ -n "$version" ]; then
            for i in "${!DEPENDENCY_NAMES[@]}"; do
                if [[ "${DEPENDENCY_NAMES[i]}" == "$name" ]]; then
                    if [[ "$chart_type" == "subchart" ]]; then
                        echo "  ✓ Updated $name (subchart): $version"
                        DEPENDENCY_VERSIONS[i]="$version"
                    else
                        echo "  ✓ Skipping root chart $name (subchart exists)"
                    fi
                    return 0
                fi
            done
            
            DEPENDENCY_NAMES+=("$name")
            DEPENDENCY_VERSIONS+=("$version")
            echo "  ✓ Added $name version: $version"
            return 0
        fi
    fi
    return 0  # Never fail, just return
}

# --- Repository Selection ---
# Use a specific, hardcoded list of repositories instead of fetching all of them.
echo "Using a defined list of repositories to process..."
REPOS="alaffia-apps
gpt-search
graphql_api
file-api
autodor-py
document-api
reports
fdw"
echo "--- Target Repositories ---"
echo "$REPOS"
echo "--------------------------"


while IFS= read -r repo; do
    echo -e "\n▷ Processing: $repo"
    
    # Get default branch
    default_branch=""
    for retry in {1..3}; do
        default_branch=$(safe_gh repo view "$ORG/$repo" --json defaultBranchRef -q '.defaultBranchRef.name')
        [ -n "$default_branch" ] && break
        echo "  ❗ Failed to get default branch (attempt $retry/3)"
        sleep 1
    done
    
    [ -z "$default_branch" ] && { echo "  ❗ Skipping - no default branch"; continue; }
    echo "  Default branch: $default_branch"

    # Process subcharts
    product_folders=$(safe_gh api "repos/$ORG/$repo/contents/charts?ref=$default_branch" --jq '.[].name?')
    if [ -n "$product_folders" ] && [[ "$product_folders" != *"message"* ]]; then
        echo "  Found subcharts:"
        while IFS= read -r product; do
            [ -n "$product" ] && process_chart "$repo" "$default_branch" "charts/$product" "$product" "subchart"
        done <<< "$product_folders"
    fi

    # Process root chart
    process_chart "$repo" "$default_branch" "chart" "$repo" "root"

done <<< "$REPOS"

# Handle graphql_api special case
for i in "${!DEPENDENCY_NAMES[@]}"; do
    if [[ "${DEPENDENCY_NAMES[i]}" == "graphql_api" ]]; then
        DEPENDENCY_NAMES[i]="graphql"
        echo "Applied graphql_api → graphql mapping"
    fi
done

echo -e "\n⏳ Updating Platform Chart..."
for i in "${!DEPENDENCY_NAMES[@]}"; do
    name="${DEPENDENCY_NAMES[i]}"
    version="${DEPENDENCY_VERSIONS[i]}"
    echo "  Updating $name → $version"
    yq -i "(.dependencies[] | select(.name == \"$name\") | .version) = \"$version\"" "$PLATFORM_CHART_PATH"
done

echo -e "\n✅ Final Platform Chart versions:"
yq '.dependencies[] | [.name, .version] | @tsv' "$PLATFORM_CHART_PATH"
echo "Platform Chart updated successfully"
