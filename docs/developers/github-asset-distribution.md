# GitHub Asset Distribution System

## Overview

Panda CMS uses a GitHub Release-based asset distribution system to solve CI environment issues with JavaScript and CSS compilation. This system pre-compiles assets and distributes them via GitHub releases, ensuring consistent asset availability across all environments.

## Problem Solved

Previously, CI environments had issues with:
- Complex asset pipeline compilation in headless environments
- JavaScript module bundling failures
- Inconsistent asset loading between local and CI environments
- Rails 8 / Propshaft compatibility issues

## How It Works

### 1. Asset Compilation Workflow

The system uses a GitHub Actions workflow (`.github/workflows/release-assets.yml`) that:

1. **Compiles Assets**: Creates optimized JavaScript and CSS bundles
2. **Generates Manifest**: Creates a manifest with file metadata and integrity hashes
3. **Uploads to GitHub**: Publishes assets to GitHub releases for public access
4. **Verifies Accessibility**: Tests that assets are publicly available

### 2. Asset Loading Strategy

The `Panda::CMS::AssetLoader` class automatically determines asset source:

```ruby
# Production or when explicitly enabled
if Rails.env.production? || ENV['PANDA_CMS_USE_GITHUB_ASSETS'] == 'true'
  # Load from GitHub: https://github.com/tastybamboo/panda-cms/releases/download/v0.7.4/
else
  # Load from local development assets
end
```

### 3. Asset Structure

Compiled assets include:

- **JavaScript Bundle**: `panda-cms-{version}.js` - Simplified Stimulus controllers
- **CSS Bundle**: `panda-cms-{version}.css` - Basic styles for admin interface
- **Manifest**: `manifest.json` - File metadata, sizes, and SHA256 hashes

## Usage

### For CI/Testing

Enable GitHub assets in your test environment:

```bash
# Single test run
PANDA_CMS_USE_GITHUB_ASSETS=true bundle exec rspec

# In CI environment variables
PANDA_CMS_USE_GITHUB_ASSETS: "true"
```

### For Development

By default, development uses local assets. To test with GitHub assets:

```bash
# Test GitHub asset loading
PANDA_CMS_USE_GITHUB_ASSETS=true bundle exec ruby test_github_assets.rb

# Run specs with GitHub assets
PANDA_CMS_USE_GITHUB_ASSETS=true bundle exec rspec spec/system/
```

## Asset Creation Process

### Automated via Releases

When a new release is created, assets are automatically compiled and uploaded:

```bash
# Create a release (triggers automatic asset compilation)
gh release create v0.8.0 --title "Release v0.8.0" --notes "Release notes"
```

### Manual Asset Creation

Trigger asset compilation manually:

```bash
# Run asset compilation workflow
gh workflow run release-assets.yml --field version=0.8.0

# Or compile locally
bundle exec rake panda_cms:assets:compile
```

### Local Asset Compilation

For development or testing:

```bash
cd spec/dummy
bundle exec rake panda_cms:assets:compile

# Assets will be created in tmp/panda_cms_assets/
ls tmp/panda_cms_assets/
# manifest.json  panda-cms-0.7.4.css  panda-cms-0.7.4.js
```

## File Structure

```
.github/workflows/
├── release-assets.yml          # Asset compilation workflow
lib/panda/cms/
├── asset_loader.rb            # Asset loading logic
lib/tasks/
├── assets.rake                # Asset compilation tasks
test_github_assets.rb          # Asset testing script
```

## Asset Compilation Details

### JavaScript Bundle

The JavaScript bundle (`panda-cms-{version}.js`) contains:

- **Simplified Stimulus Controllers**: Dashboard, theme form, and slug controllers
- **Stimulus Registration**: Automatic controller registration
- **Compatibility Layer**: Works with or without Stimulus framework
- **Version Tracking**: Includes version and loading confirmation

### CSS Bundle

The CSS bundle (`panda-cms-{version}.css`) provides:

- **Basic Admin Styles**: Essential styling for admin interface
- **Editor Styles**: Styling for content editors
- **Responsive Design**: Mobile-friendly admin interface

### Manifest Format

```json
{
  "version": "0.7.4",
  "compiled_at": "2025-07-20T18:43:32Z",
  "files": [
    {
      "filename": "panda-cms-0.7.4.js",
      "size": 1621,
      "sha256": "0d759b5451a200a8a3ced778c3f51c7395a285694b081b1cb1bca4b164307a8b"
    }
  ],
  "cdn_base_url": "https://github.com/tastybamboo/panda-cms/releases/download/v0.7.4/",
  "integrity": {
    "algorithm": "sha256"
  }
}
```

## AssetLoader API

### Key Methods

```ruby
# Check if GitHub assets should be used
Panda::CMS::AssetLoader.use_github_assets?

# Get asset URLs
Panda::CMS::AssetLoader.javascript_url
Panda::CMS::AssetLoader.css_url

# Generate HTML tags
Panda::CMS::AssetLoader.asset_tags

# Ensure assets are available
Panda::CMS::AssetLoader.ensure_assets_available!
```

### Environment Detection

The AssetLoader automatically detects the environment:

```ruby
def use_github_assets?
  Rails.env.production? ||                           # Always in production
  ENV['PANDA_CMS_USE_GITHUB_ASSETS'] == 'true' ||   # Explicitly enabled
  !development_assets_available?                     # Fallback if local unavailable
end
```

## CI Integration

### Current CI Configuration

```yaml
# .github/workflows/ci.yml
- name: "Setup GitHub-hosted assets for testing"
  env:
    PANDA_CMS_USE_GITHUB_ASSETS: "true"
  run: |
    echo "Using GitHub-hosted assets for testing"
    echo "Asset loading will be handled by Panda::CMS::AssetLoader"

- name: "Run tests with GitHub-hosted assets"
  env:
    PANDA_CMS_USE_GITHUB_ASSETS: "true"
    # ... other env vars
  run: |
    bundle exec rspec spec/system/panda/cms/admin/my_profile_spec.rb
```

### Benefits in CI

- **Consistent Environment**: Same assets across all test runs
- **Faster CI**: No asset compilation during test runs
- **Reliable Testing**: Eliminates asset-related CI failures
- **Real-world Testing**: Tests actual asset distribution mechanism

## Troubleshooting

### Testing Asset Accessibility

Use the included test script:

```bash
PANDA_CMS_USE_GITHUB_ASSETS=true bundle exec ruby test_github_assets.rb
```

Expected output:
```
🐼 Testing Panda CMS GitHub Asset Loading...
Use GitHub assets: true
📦 GitHub Asset URLs:
JavaScript: https://github.com/tastybamboo/panda-cms/releases/download/v0.7.4/panda-cms-0.7.4.js
✅ JavaScript asset accessible (1621 bytes)
✅ CSS asset accessible (548 bytes)
🎉 All tests passed!
```

### Common Issues

**Assets not found (404)**:
- Verify release exists and is published (not draft)
- Check version number matches `Panda::CMS::VERSION`
- Ensure workflow completed successfully

**CI failures**:
- Verify `PANDA_CMS_USE_GITHUB_ASSETS=true` is set
- Check that release v{version} exists and is published
- Review workflow logs for asset compilation errors

**Local development issues**:
- Ensure local assets exist or use GitHub fallback
- Check importmap configuration
- Verify Rails application setup

### Manual Verification

Check asset URLs directly:

```bash
# Test manifest
curl -I https://github.com/tastybamboo/panda-cms/releases/download/v0.7.4/manifest.json

# Test JavaScript bundle
curl -I https://github.com/tastybamboo/panda-cms/releases/download/v0.7.4/panda-cms-0.7.4.js
```

## Best Practices

### For Releases

1. **Test First**: Always test asset compilation in a draft release
2. **Verify Assets**: Check that all expected files are uploaded
3. **Test Accessibility**: Confirm assets are publicly accessible
4. **Update Documentation**: Keep version references current

### For Development

1. **Use Local Assets**: Develop with local assets when possible
2. **Test Both Modes**: Verify functionality with both local and GitHub assets
3. **Monitor Performance**: Watch for asset loading performance impacts
4. **Version Consistency**: Keep VERSION file synchronized with releases

### For CI

1. **Pin Versions**: Use specific asset versions for CI stability
2. **Cache Strategy**: Consider implementing asset caching in CI
3. **Fallback Testing**: Test both asset modes in CI pipelines
4. **Monitor Failures**: Watch for asset-related CI failures

## Performance Considerations

### GitHub CDN Benefits

- **Global Distribution**: GitHub's CDN provides worldwide asset distribution
- **Caching**: Assets are automatically cached by GitHub's infrastructure
- **Reliability**: High availability through GitHub's infrastructure

### Potential Impacts

- **Network Dependency**: Requires internet access for asset loading
- **Latency**: Small additional latency for initial asset requests
- **Bandwidth**: Uses external bandwidth for asset delivery

### Optimization Strategies

- **Asset Minimization**: Keep asset bundles small and focused
- **Compression**: Leverage GitHub's automatic gzip compression
- **Versioning**: Use version-specific URLs for optimal caching
- **Local Fallback**: Maintain local development asset capability

## Security Considerations

### Asset Integrity

- **SHA256 Hashes**: All assets include integrity hashes in manifest
- **Version Locking**: Assets are immutable once published
- **GitHub Security**: Leverages GitHub's security infrastructure

### Access Control

- **Public Assets**: Assets are publicly accessible (required for CI)
- **Version Control**: Asset versions tied to specific releases
- **Repository Access**: Asset creation requires repository write access

## Future Enhancements

### Potential Improvements

1. **Asset Optimization**: Implement minification and compression
2. **Multiple Environments**: Support for staging/preview asset versions
3. **Selective Loading**: Load only required components per page
4. **Performance Monitoring**: Track asset loading performance metrics
5. **Automated Testing**: Expanded asset validation in CI

### Migration Path

For future Rails/Propshaft improvements:
1. Monitor Rails asset pipeline developments
2. Evaluate returning to local compilation when stable
3. Maintain GitHub distribution as fallback option
4. Consider hybrid approach for different environments

## Support and Maintenance

### Monitoring

- **CI Success Rates**: Monitor test success with GitHub assets
- **Asset Accessibility**: Regular checks of asset URLs
- **Performance Metrics**: Track asset loading times
- **Release Process**: Monitor asset compilation workflow success

### Updates

- **Version Updates**: Update asset versions with each release
- **Workflow Maintenance**: Keep GitHub Actions workflow current
- **Documentation**: Maintain current usage examples and troubleshooting

For questions or issues with the asset distribution system, refer to:
- GitHub Actions workflow logs
- AssetLoader debug output
- Test script results (`test_github_assets.rb`)
