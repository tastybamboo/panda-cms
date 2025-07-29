---
title: Workflow Security
layout: default
parent: Developers
nav_order: 8
---

# Workflow Security

This guide covers how to secure GitHub Actions workflows, particularly for sensitive operations like gem releases.

## GitHub's Permission Levels

### Repository-Level Restrictions

1. **Actions Permissions** (Settings → Actions → General)
   - Disable actions entirely
   - Allow select actions only
   - Allow all actions

2. **Workflow Permissions**
   - Read repository contents (default)
   - Read and write permissions
   - Customize per workflow

### Workflow-Specific Restrictions

#### 1. Environment Protection Rules

Environments provide the strongest security for workflows:

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    environment: production  # Requires approval
```

Set up in Settings → Environments:
- **Required reviewers**: Specific users must approve
- **Deployment branches**: Restrict to main/release branches
- **Environment secrets**: Separate secrets per environment
- **Wait timer**: Delay before running

#### 2. Branch Protection Rules

Restrict workflow modifications:
- Require pull request reviews for `.github/workflows/`
- Restrict who can push to main
- Require status checks

#### 3. CODEOWNERS File

Control who can modify workflows:

```
# .github/CODEOWNERS
.github/workflows/ @owner @release-team
```

## Implementing Release Security

### Step 1: Create Production Environment

1. Go to Settings → Environments
2. Click "New environment"
3. Name it "production"
4. Configure:
   - **Required reviewers**: Add trusted maintainers
   - **Deployment branches**: Selected branches → `main`, `release/*`

### Step 2: Update Release Workflow

Modify the release workflow to require environment approval:

```yaml
jobs:
  release-gem:
    name: "Release Gem to RubyGems"
    runs-on: "ubuntu-latest"
    environment: 
      name: production
      url: https://rubygems.org/gems/panda-cms
    permissions:
      contents: write
      pull-requests: write
```

### Step 3: Manual Approval Workflow

For additional security, add a manual approval step:

```yaml
jobs:
  approve-release:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: "Approval checkpoint"
        run: echo "Release approved by ${{ github.actor }}"

  release-gem:
    needs: approve-release
    runs-on: ubuntu-latest
    # ... rest of release job
```

## Workflow Run Restrictions

### Who Can Run Workflows

By default:
- **Public repos**: Any contributor can run workflows on their PRs
- **Private repos**: Only collaborators can run workflows
- **Manual workflows**: Only users with write access

### Restricting Manual Workflow Runs

For `workflow_dispatch` events:
- Only users with **write** access can trigger
- Cannot be restricted to specific users without environments
- Use environments for user-specific restrictions

### Fork Pull Request Restrictions

Settings → Actions → General:
- **Require approval for first-time contributors**
- **Require approval for all outside collaborators**
- **Approve before running workflows from forks**

## Best Practices for Release Security

### 1. Use Multiple Environments

```yaml
# Development releases (automated)
environment: development

# Beta releases (single approval)
environment: staging

# Production releases (multiple approvals)
environment: production
```

### 2. Separate Release Permissions

Create a GitHub team for releases:
1. Create team: Settings → Teams → New team → "release-team"
2. Add trusted maintainers
3. Use team as required reviewers

### 3. Audit Workflow Runs

Monitor who triggers releases:
- Actions → Filter by workflow
- Check workflow run history
- Review actor and trigger event

### 4. Secure Secrets Management

```yaml
# Use environment-specific secrets
env:
  RUBYGEMS_API_KEY: ${{ secrets.PRODUCTION_RUBYGEMS_KEY }}
```

- Different API keys per environment
- Rotate keys regularly
- Limit secret access

## Example: Secured Release Workflow

Here's how to modify the release workflow for maximum security:

```yaml
name: "Secure Release Gem"

on:
  workflow_dispatch:
    inputs:
      version_type:
        description: "Version bump type"
        required: true
        type: choice
        options: [patch, minor, major]

jobs:
  # First job: Request approval
  request-approval:
    runs-on: ubuntu-latest
    outputs:
      approved: ${{ steps.check.outputs.approved }}
    steps:
      - name: "Request release approval"
        id: check
        run: |
          echo "Release requested by: ${{ github.actor }}"
          echo "Version type: ${{ inputs.version_type }}"
          echo "approved=pending" >> $GITHUB_OUTPUT

  # Second job: Manual approval required
  approve-release:
    needs: request-approval
    runs-on: ubuntu-latest
    environment: 
      name: production
      url: https://rubygems.org/gems/panda-cms
    steps:
      - name: "Release approved"
        run: |
          echo "✅ Release approved by: ${{ github.actor }}"
          echo "Approval time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # Third job: Actual release
  release-gem:
    needs: approve-release
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    env:
      BUNDLE_PATH: "vendor/bundle"
    steps:
      # ... rest of release steps
```

## Organization-Level Controls

For GitHub Organizations:

### 1. Base Permissions
- Settings → Member privileges → Base permissions
- Set to "Read" for most users
- Grant "Write" selectively

### 2. Team-Based Access
```
Teams:
├── developers (read access)
├── maintainers (write access)
└── release-team (write + environment access)
```

### 3. Workflow Templates
Create org-level workflow templates:
- `.github/workflow-templates/`
- Enforce security patterns
- Share across repositories

### 4. Audit Logs
Enterprise only:
- Monitor workflow executions
- Track permission changes
- Review secret access

## Monitoring and Alerts

### Set Up Notifications

1. **Webhook for Releases**
```json
{
  "name": "web",
  "active": true,
  "events": ["release", "workflow_run"],
  "config": {
    "url": "https://your-webhook-url.com",
    "content_type": "json"
  }
}
```

2. **Email Notifications**
- Watch → Custom → Releases only
- Team notifications for release events

3. **Slack/Discord Integration**
- GitHub Apps for real-time alerts
- Custom webhooks for release events

## Emergency Procedures

### Revoking Access Quickly

1. **Disable Workflow**
```bash
# Rename workflow to disable
mv .github/workflows/release-gem.yml .github/workflows/release-gem.yml.disabled
```

2. **Revoke API Keys**
- RubyGems.org → Settings → API Keys → Revoke
- Update GitHub secret immediately

3. **Lock Repository**
- Settings → Manage access → Lock repository
- Prevents all pushes temporarily

### Recovery Steps

1. Audit recent releases
2. Verify no unauthorized publishes
3. Rotate all credentials
4. Re-enable with stricter controls

## Summary

Key security measures for workflow restrictions:

| Method | Restriction Level | Use Case |
|--------|------------------|----------|
| Write permissions | Basic | General workflows |
| Environments | Strong | Production releases |
| Branch protection | Moderate | Workflow changes |
| CODEOWNERS | Moderate | Code review |
| Teams | Strong | Organization-wide |

For gem releases, we recommend:
1. **Environment protection** with required reviewers
2. **Branch protection** for workflow files
3. **Separate API keys** per environment
4. **Audit logging** of all releases