# Panda CMS Styling

## Overview

**Panda CMS does not compile or manage its own CSS.** All admin interface styling is provided by [Panda Core](https://github.com/tastybamboo/panda-core).

This architectural decision ensures:
- ✅ Consistent styling across all Panda gems
- ✅ Single source of truth for admin interface design
- ✅ Automatic style updates when Core updates
- ✅ No CSS duplication or version conflicts

## How Styling Works

### Asset Loading

CMS loads CSS from Core via a simple link tag:

```erb
<!-- In app/views/panda/cms/shared/_header.html.erb -->
<link rel="stylesheet" href="/panda-core-assets/panda-core.css">
```

Core's Rack middleware serves this file from its gem directory:

```ruby
# In panda-core/lib/panda/core/engine.rb
config.app_middleware.use(
  Rack::Static,
  urls: ["/panda-core-assets"],
  root: Panda::Core::Engine.root.join("public")
)
```

**No copying or build steps needed** - CMS automatically loads the latest CSS from wherever Core is installed.

### What's Included

The Core stylesheet provides:

- **Base Tailwind utilities** - Flexbox, spacing, colors, typography
- **Theme system** - Default and sky themes with CSS custom properties
- **EditorJS styles** - Rich text editor content formatting
- **Admin components** - Forms, buttons, panels, navigation
- **Responsive utilities** - Mobile-first breakpoints

Total size: ~37KB minified

## Customizing Styles

### Option 1: Extend with CMS-Specific CSS (Not Recommended)

You can add CMS-specific overrides, but this is generally not recommended:

```erb
<!-- In your CMS views -->
<style>
  .my-custom-cms-component {
    /* Your custom styles */
  }
</style>
```

**Why not recommended:**
- Creates inconsistency with Core's design system
- Overrides may break with Core updates
- Harder to maintain across gems

### Option 2: Contribute to Core (Recommended)

If you need new styles or components:

1. Add the component/utility to Panda Core
2. Recompile Core's CSS
3. Update CMS's Core dependency
4. Everyone benefits from the improvement!

See [Panda Core Asset Compilation Guide](https://github.com/tastybamboo/panda-core/blob/main/docs/ASSET_COMPILATION.md) for details.

## Development Workflow

### Making Style Changes

When developing features that need style updates:

1. **Identify what needs styling**:
   - New component?  → Add to Core
   - Existing component variation? → Extend in Core
   - CMS-specific one-off? → Consider if it belongs in Core

2. **Make changes in Core**:
```bash
cd /path/to/panda-core

# Edit Core styles
vim app/assets/tailwind/application.css

# Recompile CSS including CMS content
bin/compile-css

# See docs/ASSET_COMPILATION.md for full details
```

3. **Test in CMS**:
```bash
cd /path/to/panda-cms

# Ensure using local Core gem
bundle config local.panda-core /path/to/panda-core

# Restart server
bin/dev

# Visit admin interface and verify styles
```

4. **Commit changes**:
```bash
# In Core repo
git add public/panda-core-assets/panda-core.css
git add app/assets/tailwind/application.css
git commit -m "Add styles for new feature"

# In CMS repo (if needed)
git add app/views/panda/cms/...
git commit -m "Add view using new Core styles"
```

### Hot Reloading (Development)

CSS changes don't require CMS asset recompilation:

1. Edit Core's CSS source
2. Run `bin/compile-css` in Core
3. Restart server
4. Hard refresh browser (Cmd+Shift+R)

Changes are instant because CMS loads CSS from Core's gem directory.

## Theme System

### Available Themes

Panda Core provides two built-in themes:

**Default Theme** (Purple/Pink):
```css
html[data-theme="default"] {
  --color-light: 238 206 230; /* #EECEE6 - Light purple */
  --color-mid: 141 94 183;    /* #8D5EB7 - Medium purple */
  --color-dark: 33 29 73;     /* #211D49 - Dark purple */
  /* ... */
}
```

**Sky Theme** (Blue):
```css
html[data-theme="sky"] {
  --color-light: 204 238 242; /* #CCEEF2 - Light blue */
  --color-mid: 42 102 159;    /* #2A669F - Medium blue */
  --color-dark: 20 32 74;     /* #14204A - Dark blue */
  /* ... */
}
```

### Using Theme Colors

Use CSS custom properties in your components:

```css
.my-component {
  background-color: rgb(var(--color-light));
  color: rgb(var(--color-dark));
  border-color: rgb(var(--color-mid));
}
```

Or use Tailwind utilities:

```erb
<div class="bg-light text-dark border-mid">
  Content
</div>
```

### Switching Themes

Users can switch themes via their profile settings. The theme is stored in the user model and applied via the `data-theme` attribute:

```erb
<html data-theme="<%= Panda::Core::Current&.user&.current_theme || 'default' %>">
```

## Troubleshooting

### Styles Not Showing

**Check 1**: Verify Core CSS is loaded

```bash
curl http://localhost:3000/panda-core-assets/panda-core.css | head -5
```

Should show CSS content with Tailwind utilities.

**Check 2**: Verify file size

```bash
# In Core repo
ls -lh public/panda-core-assets/panda-core.css
```

Should be ~37KB. If smaller (~14KB), Core was compiled without CMS content.

**Check 3**: Clear browser cache

```
Chrome/Firefox: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
```

### Missing Utility Classes

**Symptom**: Tailwind utility class doesn't work (e.g., `bg-purple-500`)

**Cause**: Class not included in compiled CSS

**Solution**:
1. Add the class to a template file
2. Recompile Core CSS with full content
3. Commit updated CSS
4. Restart server

### Styles Look Different in Production

**Cause**: Production might be using older Core version

**Solution**:
```bash
# Check Core version in production
bundle show panda-core

# Update Core in production
bundle update panda-core

# Verify CSS file size
ls -lh $(bundle show panda-core)/public/panda-core-assets/panda-core.css
```

## Asset Compilation (CMS JavaScript Only)

While CSS is handled by Core, **CMS still compiles its own JavaScript**:

```bash
cd spec/dummy
bundle exec rake panda:cms:assets:compile
```

This creates:
- `panda-cms-{version}.js` - Stimulus controllers bundle
- `manifest.json` - Asset metadata

**CSS is NOT compiled** - that rake task will show:
```
ℹ️  CSS is provided by Panda Core at /panda-core-assets/panda-core.css
```

## Migration Notes

### Before (Old Architecture)

CMS compiled both CSS and JavaScript:
- ❌ `panda-cms-{version}.css` created by CMS
- ❌ Duplicate theme definitions in CMS
- ❌ Styling inconsistencies between Core and CMS
- ❌ Two compilation pipelines to maintain

### After (Current Architecture)

CMS only compiles JavaScript:
- ✅ CSS provided by Core
- ✅ Single source of truth for styling
- ✅ Consistent themes across all gems
- ✅ Simpler CMS asset pipeline

## Related Documentation

- [Panda Core Asset Compilation](https://github.com/tastybamboo/panda-core/blob/main/docs/ASSET_COMPILATION.md) - Complete CSS compilation guide
- [Panda Core README](https://github.com/tastybamboo/panda-core/blob/main/README.md) - Core gem overview
- [Tailwind CSS v4 Docs](https://tailwindcss.com/docs) - Framework reference
