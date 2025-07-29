# GitHub Actions Workflows

This directory contains the CI/CD workflows for Panda CMS.

## Workflows

### ci.yml - Continuous Integration
- **Trigger**: Pull requests, pushes to main, merge groups
- **Purpose**: Run tests, linters, and security checks
- **Jobs**:
  - `seclint`: Security checks and code linting
  - `specs`: Run test suite with asset compilation

### release-gem.yml - Automated Gem Release
- **Trigger**: Manual workflow dispatch
- **Purpose**: Automate the entire gem release process
- **Features**:
  - Version bumping (patch/minor/major)
  - Test execution
  - Asset compilation coordination
  - RubyGems publishing
  - PR creation
- **Required Secrets**:
  - `RUBYGEMS_API_KEY`: For publishing to RubyGems
  - `RAILS_MASTER_KEY`: For running tests

### release-assets.yml - Asset Compilation & Distribution
- **Trigger**: Release creation/publication or manual dispatch
- **Purpose**: Compile and upload JavaScript/CSS assets to GitHub releases
- **Process**:
  - Compiles assets in clean environment
  - Uploads to GitHub release
  - Verifies accessibility
  - Tests asset loading

### monitor-assets.yml - Asset Health Monitoring
- **Trigger**: Every 6 hours or manual dispatch
- **Purpose**: Monitor GitHub-hosted asset performance and availability
- **Features**:
  - Performance benchmarking
  - Availability checking
  - Continuous monitoring mode
  - Alert generation

### codeql.yml - Security Analysis
- **Trigger**: Push, pull request, weekly schedule
- **Purpose**: Run GitHub's CodeQL security analysis
- **Languages**: Ruby, JavaScript

### docs.yml - Documentation Site
- **Trigger**: Push to main (docs/ changes)
- **Purpose**: Build and deploy Jekyll documentation site
- **Deployment**: GitHub Pages

## Workflow Relationships

```
Release Process:
1. release-gem.yml (creates tag)
   ↓
2. release-assets.yml (triggered by tag)
   ↓
3. Assets uploaded to release
   ↓
4. release-gem.yml continues (publishes gem)
```

## Required Secrets

Configure these in Settings → Secrets → Actions:

- `RUBYGEMS_API_KEY`: API key from rubygems.org
- `RAILS_MASTER_KEY`: Rails master key for tests
- `GITHUB_TOKEN`: Automatically provided by GitHub

## Manual Workflow Triggers

Several workflows support manual triggering:

### Release Gem
```
Actions → Release Gem → Run workflow
Options:
- Version type: patch/minor/major
- Specific version: Override automatic versioning
- Dry run: Test without publishing
- Skip tests: Emergency releases only
```

### Release Assets
```
Actions → Release Assets → Run workflow
Options:
- Version: Asset version to compile
```

### Monitor Assets
```
Actions → Asset Performance Monitoring → Run workflow
Options:
- Monitoring type: performance/baseline/report
- Continuous minutes: Duration for continuous monitoring
```

## Best Practices

1. **Always test workflows** in a branch before merging
2. **Use dry run** mode for release workflows when testing
3. **Monitor workflow runs** for failures
4. **Keep secrets secure** and rotate periodically
5. **Document changes** to workflows in PRs

## Troubleshooting

### Common Issues

**Workflow not triggering**
- Check trigger conditions match your action
- Verify workflow file is valid YAML
- Check GitHub Actions is enabled for repo

**Permission errors**
- Verify workflow has required permissions
- Check secrets are configured correctly
- Ensure GitHub token has necessary scopes

**Asset compilation failures**
- Check Rails environment setup
- Verify database connection
- Review asset compilation logs

**Release failures**
- Ensure version doesn't already exist
- Verify RubyGems API key is valid
- Check network connectivity

### Debugging

Enable debug logging:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## Maintenance

- Review and update workflows quarterly
- Update action versions regularly
- Monitor deprecation notices
- Test workflows after major changes