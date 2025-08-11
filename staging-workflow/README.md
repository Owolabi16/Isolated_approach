# Staging Workflow

## Overview

The **Automate Staging Release Process** GitHub Action is a composite action designed to automate the staging release process for platform charts. It integrates TypeScript scripts, shell scripts, and GitHub CLI commands to streamline the release process, ensuring consistency and efficiency.

---

## Purpose

This action automates the following tasks:
1. **Authentication**: Configures Git and GitHub CLI for secure operations.
2. **Service Chart Updates**: Updates Helm chart versions in service repositories.
3. **Pull Request Management**: Merges service PRs and creates/merges PRs for infrastructure changes.
4. **Workflow Monitoring**: Monitors GitHub Actions workflows for successful execution.
5. **Platform Chart Updates**: Updates the platform chart with the latest dependencies and commits changes.

---

## Inputs

| Input Name       | Description                              | Required |
|------------------|------------------------------------------|----------|
| `release_version`| The platform version in `x-x-x` format. | Yes      |
| `github_token`   | GitHub token for authentication.         | Yes      |
| `github_actor`   | GitHub actor/username for operations.    | Yes      |

---

## Outputs

| Output Name        | Description                              |
|--------------------|------------------------------------------|
| `platform_version` | The final version of the platform chart. |

---

## Workflow Steps

### 1. **Setup Node.js Environment**
- **Purpose**: Ensures the required Node.js environment is available for running TypeScript scripts.
- **Implementation**:
  ```yaml
  uses: actions/setup-node@v4
  with:
    node-version: '22.x'
  ```

---

### 2. **Configure Git Environment**
- **Purpose**: Configures Git and GitHub CLI for secure operations.
- **Implementation**:
  ```bash
  git config user.name "${{ inputs.github_actor }}"
  git config user.email "${{ inputs.github_actor }}@users.noreply.github.com"
  echo "GITHUB_TOKEN=${{ inputs.github_token }}" >> $GITHUB_ENV
  gh auth setup-git
  ```

---

### 3. **Execute Workflow Steps**
- **Purpose**: Executes the main workflow logic using the main.sh script.
- **Implementation**:
  ```bash
  export PATH="$PATH:${{ github.action_path }}/scripts"
  scripts/main.sh \
    "${{ inputs.release_version }}" \
    "${{ inputs.github_token }}" \
    "${{ inputs.github_actor }}"
  ```
- **Details**:
  - The main.sh script orchestrates the following:
    1. **Authentication**: Authenticates with GitHub using auth_git.sh.
    2. **Service Chart Updates**: Updates Helm chart versions in service repositories using update_service_chart_versions.sh.
    3. **Merge Service PRs**: Merges service PRs using merge_service_pr.sh.
    4. **Monitor Workflows**: Monitors release workflows using the TypeScript script monitor_release.ts.
    5. **Update Infra Chart**: Updates the platform chart in the infrastructure repository using update_infra_chart_versions.sh.
    6. **Commit Changes**: Commits changes to the infrastructure repository using commit_changes.sh.
    7. **Merge Infra PR**: Merges the infrastructure PR using merge_infra_pr.sh.

---

### 4. **Capture Platform Version**
- **Purpose**: Extracts the final platform chart version and sets it as an output.
- **Implementation**:
  ```bash
  VERSION=$(yq e '.version' charts/platform/Chart.yaml)
  echo "platform_version=$VERSION" >> $GITHUB_OUTPUT
  ```

---

## Supporting Files

### 1. **Shell Scripts**
The action relies on several shell scripts located in the `scripts/` directory:

| Script Name                     | Description                                                                 |
|---------------------------------|-----------------------------------------------------------------------------|
| auth_git.sh                   | Authenticates with GitHub and configures Git.                               |
| update_service_chart_versions.sh | Updates Helm chart versions in service repositories.                        |
| merge_service_pr.sh           | Merges open pull requests for service repositories.                         |
| update_infra_chart_versions.sh| Updates the platform chart in the infrastructure repository.                |
| commit_changes.sh             | Commits changes to the infrastructure repository.                          |
| merge_infra_pr.sh             | Merges the infrastructure pull request.                                    |
| main.sh                       | Orchestrates the entire workflow by calling the above scripts sequentially. |

---

### 2. **TypeScript Script**
The monitor_release.ts script monitors GitHub Actions workflows for successful execution. It:
- Loads merged repositories from a file (`merged-repos.txt`).
- Finds recent workflow runs for each repository.
- Monitors the status of each workflow run until completion or timeout.

---

## Key Features

1. **End-to-End Automation**: Automates the entire staging release process, from updating charts to merging PRs.
2. **Error Handling**: Includes robust error handling in shell scripts and TypeScript code.
3. **Workflow Monitoring**: Ensures workflows complete successfully before proceeding.
4. **Version Management**: Updates platform chart versions and dependencies dynamically.

---

## Example Usage

```yaml
jobs:
  automate-staging-release:
    runs-on: ubuntu-latest
    steps:
      - name: Automate Staging Release
        uses: ./staging-workflow
        with:
          release_version: "1-0-0"
          github_token: ${{ secrets.GITHUB_TOKEN }}
          github_actor: ${{ github.actor }}
```

---

## Error Handling

| Error Type                     | Handling Mechanism                                                   |
|--------------------------------|----------------------------------------------------------------------|
| Invalid `release_version`      | Validates input format and exits with an error if invalid.           |
| Workflow Timeout               | Monitors workflows and fails if they exceed the maximum wait time.   |
| GitHub API Errors              | Retries API calls or logs errors for manual intervention.            |
| Missing Dependencies           | Logs missing dependencies and exits with an error.                  |

---

## Observability

- **Logs**: Each step logs detailed information for debugging.
- **Outputs**: The final platform chart version is captured as an output for downstream workflows.

---

## Conclusion

The **Automate Staging Release Process** GitHub Action is a comprehensive solution for managing staging releases. It ensures consistency, reduces manual effort, and provides robust error handling and observability.