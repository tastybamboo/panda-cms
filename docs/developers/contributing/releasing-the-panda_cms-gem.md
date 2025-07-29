---
title: Releasing the panda-cms gem
layout: default
parent: Contributing
---

## Quick Release Guide

For the complete release process including asset compilation and distribution, see the [comprehensive release documentation](/developers/releasing).

### Prerequisites

- Install [gem-release](https://github.com/svenfuchs/gem-release): `gem install gem-release`
- Ensure you have publishing rights on RubyGems
- Have GitHub CLI (`gh`) installed and authenticated

### Quick Release Commands

```bash
# Set version (automatically determines next patch version)
RELEASE_VERSION=$(gem bump --pretend --no-commit | awk '{ print $4 }' | tr -d '[:space:]')

# Or set manually for minor/major releases
RELEASE_VERSION=0.8.0

# Create release
git checkout -b release/v$RELEASE_VERSION
gem bump --no-commit --version $RELEASE_VERSION
bundle update
git commit -am "Release v$RELEASE_VERSION"
git tag -a v$RELEASE_VERSION -m "Release v$RELEASE_VERSION"
git push origin release/v$RELEASE_VERSION --tags

# Wait for GitHub Actions to compile and upload assets
# Then build and publish gem
gem build panda-cms.gemspec
gem push panda-cms-$RELEASE_VERSION.gem

# Merge and cleanup
git checkout main && git merge release/v$RELEASE_VERSION
git push origin main
git push origin :release/v$RELEASE_VERSION
```

### Important Notes

- **Assets must be compiled**: The GitHub Actions workflow will automatically compile and upload assets when you push the tag
- **Wait for asset upload**: Ensure the release assets workflow completes before publishing the gem
- **Verify the release**: Test that assets are accessible using `PANDA_CMS_VERSION=$RELEASE_VERSION ruby test_github_assets.rb`

For detailed instructions, troubleshooting, and the complete release process, see the [full release documentation](/developers/releasing).
