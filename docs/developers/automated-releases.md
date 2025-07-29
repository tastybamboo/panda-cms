---
title: Automated Releases
layout: default
parent: Developers
nav_order: 7
---

# Automated Releases

Panda CMS supports fully automated gem releases through GitHub Actions, eliminating the need for manual release processes.

## Overview

The automated release workflow (`release-gem.yml`) handles:
- Version bumping (patch, minor, major)
- Running the test suite
- Creating release branches and tags
- Waiting for asset compilation
- Publishing to RubyGems
- Creating pull requests for merging

## Prerequisites

### GitHub Secrets Setup

Before using automated releases, you must configure the following GitHub secrets:

1. **RUBYGEMS_API_KEY** (Required)
   - Get your API key from [RubyGems.org](https://rubygems.org/profile/edit)
   - Add it to your repository: Settings → Secrets → Actions → New repository secret
   - Name: `RUBYGEMS_API_KEY`
   - Value: Your RubyGems API key

2. **RAILS_MASTER_KEY** (Required for tests)
   - Already configured if CI is working
   - Used for running tests before release

## Using Automated Releases

### Quick Release

To release a new version:

1. Go to Actions → Release Gem → Run workflow
2. Choose version type:
   - **patch**: Bug fixes (0.7.4 → 0.7.5)
   - **minor**: New features (0.7.4 → 0.8.0)
   - **major**: Breaking changes (0.7.4 → 1.0.0)
3. Click "Run workflow"

### Advanced Options

The workflow provides several options:

- **Version type**: patch, minor, or major
- **Specific version**: Override automatic versioning (e.g., "0.8.0-beta1")
- **Dry run**: Test the release process without publishing
- **Skip tests**: Not recommended, but available for emergencies

### Dry Run Mode

Test the release process without making changes:

```yaml
Dry run: true
```

This will:
- Show what version would be created
- Build the gem locally
- Display what would be published
- Skip all git operations and publishing

## Release Process Flow

1. **Version Determination**
   - Calculates next version based on type
   - Or uses specific version if provided

2. **Pre-flight Checks**
   - Verifies version doesn't already exist
   - Runs test suite (unless skipped)

3. **Release Creation**
   - Creates release branch
   - Bumps version in `version.rb`
   - Updates `Gemfile.lock`
   - Commits changes

4. **Asset Compilation**
   - Creates and pushes tag
   - Triggers `release-assets.yml` workflow
   - Waits for assets to be uploaded

5. **Gem Publishing**
   - Builds gem file
   - Publishes to RubyGems
   - Verifies availability

6. **Cleanup**
   - Creates PR to merge release branch
   - Provides summary and next steps

## Example Workflow Runs

### Patch Release
```yaml
Version type: patch
Dry run: false
Skip tests: false
# 0.7.4 → 0.7.5
```

### Minor Release with Dry Run
```yaml
Version type: minor
Dry run: true
Skip tests: false
# Would create 0.8.0 but doesn't publish
```

### Specific Beta Version
```yaml
Version type: patch
Version: 0.8.0-beta1
Dry run: false
# Creates exact version specified
```

## Post-Release Steps

After the workflow completes:

1. **Review the Pull Request**
   - Check the generated PR
   - Verify version changes
   - Merge when ready

2. **Delete Release Branch**
   ```bash
   git push origin :release/v0.7.5
   ```

3. **Verify Release**
   ```bash
   gem list -r panda-cms -a | grep 0.7.5
   ```

4. **Update Documentation**
   - Add release notes
   - Update version references
   - Announce the release

## Monitoring Releases

### During Release
- Watch the workflow progress in Actions tab
- Check logs for each step
- Monitor asset compilation status

### After Release
- Verify gem on [RubyGems.org](https://rubygems.org/gems/panda-cms)
- Check GitHub release page
- Test gem installation

## Troubleshooting

### Common Issues

**Authentication Failed**
```
ERROR:  While executing gem ... (Gem::InvalidSpecificationException)
```
- Verify RUBYGEMS_API_KEY secret is set correctly
- Check API key hasn't expired

**Version Already Exists**
```
❌ Version v0.7.5 already exists!
```
- Choose a different version
- Check existing tags: `git tag --list`

**Asset Compilation Timeout**
```
⚠️ Asset compilation timeout - proceeding anyway
```
- Check release-assets workflow
- Assets may still upload after gem publishes
- Can manually trigger asset workflow if needed

**Test Failures**
```
🧪 Running test suite...
Failures: 1
```
- Fix failing tests before releasing
- Or use skip_tests in emergency (not recommended)

### Manual Recovery

If automated release fails partway:

1. **Check what was completed**
   ```bash
   git tag --list | grep v0.7.5
   gem list -r panda-cms -a | grep 0.7.5
   ```

2. **Clean up if needed**
   ```bash
   # Delete local tag
   git tag -d v0.7.5
   
   # Delete remote tag
   git push origin :refs/tags/v0.7.5
   
   # Delete branch
   git push origin :release/v0.7.5
   ```

3. **Retry or complete manually**
   - Run workflow again with dry_run first
   - Or follow manual release process

## Security Considerations

### API Key Management
- Never commit API keys
- Rotate keys periodically
- Use least privilege (push access only)

### Workflow Permissions
- Workflow has write access to:
  - Contents (for tags/branches)
  - Pull requests (for creating PRs)
- No access to settings or other secrets

### Protected Branches
- Consider branch protection rules
- Require PR reviews for releases
- Restrict who can run workflows

## Best Practices

1. **Always Test First**
   - Use dry run for major releases
   - Verify in development environment

2. **Version Appropriately**
   - Follow semantic versioning
   - Use beta/rc for pre-releases

3. **Document Changes**
   - Update CHANGELOG.md
   - Write clear release notes
   - Communicate breaking changes

4. **Monitor Releases**
   - Watch workflow execution
   - Verify gem availability
   - Check for user issues

5. **Regular Releases**
   - Release often with small changes
   - Easier to track issues
   - Reduces risk

## Comparison with Manual Process

| Task | Manual | Automated |
|------|--------|-----------|
| Run tests | `bundle exec rspec` | ✅ Automatic |
| Bump version | `gem bump` | ✅ Automatic |
| Create tag | `git tag -a` | ✅ Automatic |
| Build gem | `gem build` | ✅ Automatic |
| Wait for assets | Manual checking | ✅ Automatic |
| Publish gem | `gem push` | ✅ Automatic |
| Create PR | `gh pr create` | ✅ Automatic |
| Time required | 15-20 minutes | 5-10 minutes |
| Human errors | Possible | Minimized |

## Future Enhancements

Potential improvements to the automated release process:

1. **Changelog Generation**
   - Automated from PR titles
   - Conventional commits support

2. **Release Approval**
   - Required reviews for major versions
   - Environment-based approvals

3. **Rollback Support**
   - Automated version yanking
   - Revert workflows

4. **Release Notifications**
   - Slack/Discord webhooks
   - Email notifications

5. **Performance Metrics**
   - Bundle size tracking
   - Dependency analysis