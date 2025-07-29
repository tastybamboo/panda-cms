---
title: Releasing Panda CMS
layout: default
parent: Developers
nav_order: 6
---

# Releasing Panda CMS

This guide covers the complete release process for Panda CMS, including asset compilation, GitHub releases, and gem publication.

## Overview

Panda CMS supports two release methods:
1. **Automated Release** (Recommended) - Using GitHub Actions workflow
2. **Manual Release** - Traditional command-line process

The release process involves:
1. Preparing the codebase for release
2. Compiling and distributing assets via GitHub releases
3. Publishing the gem to RubyGems
4. Verifying the release

## Automated Release (Recommended)

For a fully automated release process, see the [Automated Releases documentation](./automated-releases). This method:
- Handles all steps automatically
- Reduces human error
- Ensures consistent releases
- Takes 5-10 minutes

Quick start:
1. Go to Actions → Release Gem → Run workflow
2. Select version type (patch, minor, major)
3. Click "Run workflow"

## Manual Release Process

The following sections describe the traditional manual release process.

## Prerequisites

### Required Tools

- **Ruby and Bundler**: For building and publishing the gem
- **GitHub CLI (`gh`)**: For creating releases and uploading assets
- **gem-release**: For version management (`gem install gem-release`)
- **Git**: For version control and tagging

### Required Permissions

- Write access to the Panda CMS repository
- RubyGems publishing rights for `panda-cms`
- GitHub release creation permissions

## Release Process

### 1. Prepare the Release

First, ensure all tests are passing and the codebase is ready:

```bash
# Ensure you're on main branch with latest changes
git checkout main
git pull origin main

# Run all tests
bundle exec rspec

# Run linters and security checks
bundle exec standardrb
bundle exec brakeman --quiet
bundle exec erb_lint app/views --lint-all
yamllint -c .yamllint .
```

### 2. Determine Version Number

Use semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

```bash
# Check current version
cat lib/panda/cms/version.rb

# Preview next patch version
RELEASE_VERSION=$(gem bump --pretend --no-commit | awk '{ print $4 }' | tr -d '[:space:]')
echo $RELEASE_VERSION

# Or set manually for minor/major releases
RELEASE_VERSION=0.8.0
```

### 3. Create Release Branch

```bash
# Create release branch
git checkout -b release/v$RELEASE_VERSION

# Update version
gem bump --no-commit --version $RELEASE_VERSION

# Update dependencies
bundle update

# Commit changes
git commit -am "Release v$RELEASE_VERSION"
```

### 4. Compile and Upload Assets

Assets must be compiled and uploaded to GitHub for distribution:

```bash
# Compile assets locally (from spec/dummy directory)
cd spec/dummy
bundle exec rake panda_cms:assets:compile
cd ../..

# Verify compiled assets
ls -la spec/dummy/tmp/panda_cms_assets/
# Should show: manifest.json, panda-cms-X.Y.Z.js, panda-cms-X.Y.Z.css

# Create GitHub release tag
git tag -a v$RELEASE_VERSION -m "Release v$RELEASE_VERSION"
git push origin release/v$RELEASE_VERSION --tags

# Assets will be automatically compiled and uploaded by GitHub Actions
# Monitor the release workflow: https://github.com/tastybamboo/panda-cms/actions
```

Alternatively, manually upload assets:

```bash
# Create release on GitHub
gh release create v$RELEASE_VERSION \
  --title "Release v$RELEASE_VERSION" \
  --notes "Release notes here" \
  --draft

# Upload compiled assets
cd spec/dummy
bundle exec rake panda_cms:assets:upload
cd ../..

# Publish the release
gh release edit v$RELEASE_VERSION --draft=false
```

### 5. Build and Publish Gem

Once assets are uploaded and available:

```bash
# Build the gem
gem build panda-cms.gemspec

# Publish to RubyGems
gem push panda-cms-$RELEASE_VERSION.gem

# Merge release branch
git checkout main
git merge release/v$RELEASE_VERSION
git push origin main

# Delete release branch
git push origin :release/v$RELEASE_VERSION
git branch -d release/v$RELEASE_VERSION
```

### 6. Verify Release

Verify the release is working correctly:

```bash
# Test asset availability
PANDA_CMS_VERSION=$RELEASE_VERSION ruby test_github_assets.rb

# Verify gem installation
gem install panda-cms -v $RELEASE_VERSION

# In a test Rails app
bundle add panda-cms --version "~> $RELEASE_VERSION"
```

## Asset Distribution System

### How Assets Work

Panda CMS uses a GitHub-based asset distribution system:

1. **Development**: Uses local importmap-based assets
2. **Test/CI**: Uses pre-compiled assets from GitHub releases
3. **Production**: Downloads assets from GitHub releases

### Asset Compilation

The `panda_cms:assets:compile` rake task:
- Bundles all JavaScript controllers into a single file
- Creates a simplified CSS bundle
- Generates a manifest with integrity hashes
- Copies assets to test locations

### Asset URLs

Assets are served from:
```
https://github.com/tastybamboo/panda-cms/releases/download/v{VERSION}/panda-cms-{VERSION}.js
https://github.com/tastybamboo/panda-cms/releases/download/v{VERSION}/panda-cms-{VERSION}.css
https://github.com/tastybamboo/panda-cms/releases/download/v{VERSION}/manifest.json
```

## Automated Workflows

### CI Asset Compilation

The CI workflow (`ci.yml`) automatically compiles assets for testing:

```yaml
- name: "Compile assets"
  working-directory: spec/dummy
  run: |
    bundle exec rake panda_cms:assets:compile
```

### Release Asset Upload

The release workflow (`release-assets.yml`) handles asset distribution:
- Triggers on release creation
- Compiles assets in clean environment
- Uploads to GitHub release
- Verifies accessibility

### Asset Monitoring

The monitoring workflow (`monitor-assets.yml`) checks asset health:
- Runs every 6 hours
- Tests asset accessibility
- Reports performance metrics
- Can be triggered manually for debugging

## Troubleshooting Releases

### Asset Compilation Fails

If asset compilation fails:

```bash
# Debug compilation locally
cd spec/dummy
RAILS_ENV=test bundle exec rake panda_cms:assets:compile --trace

# Check for missing files
ls -la ../../app/javascript/panda/cms/controllers/

# Verify engine path
bundle exec rails runner "puts Panda::CMS::Engine.root"
```

### GitHub Release Issues

If GitHub release creation fails:

```bash
# Check GitHub CLI authentication
gh auth status

# List existing releases
gh release list

# Delete draft release and retry
gh release delete v$RELEASE_VERSION --yes
```

### Gem Publishing Issues

If gem publishing fails:

```bash
# Verify RubyGems credentials
gem signin

# Check gem build
gem build panda-cms.gemspec

# List built gems
ls *.gem

# Try publishing with verbose output
gem push panda-cms-$RELEASE_VERSION.gem --verbose
```

### Asset Loading Issues

To debug asset loading:

```bash
# Test asset URLs directly
curl -I https://github.com/tastybamboo/panda-cms/releases/download/v$RELEASE_VERSION/manifest.json

# Run asset test script
PANDA_CMS_VERSION=$RELEASE_VERSION ruby test_github_assets.rb

# Force GitHub assets in development
PANDA_CMS_USE_GITHUB_ASSETS=true bundle exec rails server
```

## Release Checklist

- [ ] All tests passing
- [ ] Linters and security checks pass
- [ ] Version number updated
- [ ] Release notes written
- [ ] Assets compiled successfully
- [ ] GitHub release created and published
- [ ] Assets uploaded and accessible
- [ ] Gem built and published to RubyGems
- [ ] Release branch merged to main
- [ ] Release verified working

## Post-Release Tasks

After releasing:

1. **Update Documentation**: Update version references in docs
2. **Announce Release**: Post to relevant channels
3. **Monitor Issues**: Watch for bug reports
4. **Update Changelog**: Document changes

## Emergency Procedures

### Yanking a Release

If a critical issue is found:

```bash
# Yank from RubyGems
gem yank panda-cms -v $RELEASE_VERSION

# Mark GitHub release as pre-release
gh release edit v$RELEASE_VERSION --prerelease

# Create patch release with fix
```

### Rolling Back

To roll back a release:

1. Revert commits on main branch
2. Create new patch release with fixes
3. Communicate with users about the issue

## Best Practices

1. **Test Thoroughly**: Run full test suite before releasing
2. **Document Changes**: Write clear release notes
3. **Version Assets**: Keep assets in sync with gem version
4. **Monitor Releases**: Check asset availability after release
5. **Communicate**: Inform users of breaking changes

## Release Notes Template

```markdown
# Release v{VERSION}

## What's Changed

### Features
- New feature description

### Bug Fixes
- Fixed issue description

### Breaking Changes
- Description of breaking changes (if any)

### Dependencies
- Updated dependencies

## Upgrade Instructions

```ruby
bundle update panda-cms
```

## Contributors
- @username

**Full Changelog**: https://github.com/tastybamboo/panda-cms/compare/v{PREVIOUS}...v{VERSION}
```