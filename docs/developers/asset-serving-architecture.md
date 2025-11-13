# Asset Serving Architecture

## Overview

Panda's asset serving system is designed to support multiple gems (panda-core, panda-cms, future gems like CMS Pro) with automatic discovery and unified serving of JavaScript modules and CSS files. The system uses a **ModuleRegistry** pattern for self-registration and custom Rack middleware for efficient asset delivery.

## Architecture Components

### 1. ModuleRegistry (panda-core)

The `Panda::Core::ModuleRegistry` is the central registry where all Panda gems register themselves for asset compilation and serving.

**Location**: `panda-core/lib/panda/core/module_registry.rb`

**Key Features**:
- Self-registration pattern - gems register themselves
- Automatic path discovery via importmap introspection
- Tailwind CSS content path aggregation
- Custom JavaScript serving middleware

**Registration Example**:
```ruby
# In panda-cms/lib/panda/cms/engine.rb
Panda::Core::ModuleRegistry.register(
  gem_name: "panda-cms",
  engine: "Panda::CMS::Engine",
  paths: {
    views: "app/views/panda/cms/**/*.erb",
    components: "app/components/panda/cms/**/*.rb"
    # JavaScript paths are auto-discovered from config/importmap.rb
  }
)
```

### 2. JavaScriptMiddleware

Custom Rack middleware that serves JavaScript modules from all registered Panda gems.

**Location**: `panda-core/lib/panda/core/module_registry.rb` (JavaScriptMiddleware class)

**How It Works**:

1. Intercepts requests to `/panda/*` (e.g., `/panda/core/application.js`, `/panda/cms/admin/slug_controller.js`)
2. Strips `/panda/` prefix to get relative path
3. Searches through all registered modules' `app/javascript/panda/` directories
4. Serves from first matching location
5. Returns proper Content-Type headers and cache control

**Middleware Stack Position**:
```ruby
# In panda-core/lib/panda/core/engine.rb
app.config.middleware.insert_before Propshaft::Server,
  Panda::Core::ModuleRegistry::JavaScriptMiddleware
```

**Why Before Propshaft**: Propshaft intercepts requests and can prevent our middleware from seeing them. By inserting before Propshaft, we ensure `/panda/*` requests are handled by our custom middleware first.

**Key Code**:
```ruby
def call(env)
  request = Rack::Request.new(env)
  path = request.path_info

  # Only handle /panda/* requests
  return @app.call(env) unless path.start_with?("/panda/")

  # Strip /panda/ prefix
  relative_path = path.sub(%r{^/panda/}, "")

  # Find file across all registered modules
  file_path = find_javascript_file(relative_path)

  if file_path && File.file?(file_path)
    serve_file(file_path, env)
  else
    @app.call(env)  # Pass to next middleware
  end
end

private

def find_javascript_file(relative_path)
  ModuleRegistry.modules.each do |gem_name, info|
    # Check each module's app/javascript/panda/ directory
    candidate = engine_root(info[:engine]).join("app/javascript/panda", relative_path)
    return candidate.to_s if candidate.exist? && candidate.file?
  end
  nil
end
```

### 3. CSS Compilation via Tailwind

CSS is compiled by panda-core using Tailwind, aggregating content from all registered modules.

**Compilation Process**:

1. **Content Discovery**: ModuleRegistry collects all Tailwind content paths from registered modules
2. **Aggregation**: Paths are combined into a single Tailwind compilation command
3. **Auto-compilation**: In test environment, CSS compiles automatically on first boot
4. **Cache Busting**: Uses timestamp-based filenames for dev/test, semantic versions for production

**Example**:
```bash
# Auto-compilation in test environment
bundle exec tailwindcss \
  -i panda-core/app/assets/tailwind/application.css \
  -o panda-core/public/panda-core-assets/panda-core-1762886534.css \
  --content 'panda-core/app/views/panda/core/**/*.erb' \
  --content 'panda-core/app/components/panda/core/**/*.rb' \
  --content 'panda-cms/app/views/panda/cms/**/*.erb' \
  --content 'panda-cms/app/components/panda/cms/**/*.rb' \
  --minify
```

**Location**: `panda-core/lib/panda/core/engine.rb` (auto-compilation initializer)

### 4. Static Asset Middleware (Rack::Static)

Each gem serves its own public assets (compiled bundles, images, etc.) via standard Rack::Static middleware.

**panda-core**:
```ruby
# Serves from public/panda-core-assets/
app.config.middleware.insert_before Propshaft::Server, Rack::Static,
  urls: ["/panda-core-assets"],
  root: Panda::Core::Engine.root.join("public"),
  header_rules: [
    [:all, {"Cache-Control" => Rails.env.development? ?
      "no-cache, no-store, must-revalidate" :
      "public, max-age=31536000"}]
  ]
```

**panda-cms**:
```ruby
# Serves from public/panda-cms-assets/
app.config.middleware.use Rack::Static,
  urls: ["/panda-cms-assets"],
  root: Panda::CMS::Engine.root.join("public")
```

## Asset Types and Serving Strategies

### JavaScript Modules

**Development Environment**:
- Uses **importmaps** with individual ES modules
- Files loaded directly from `app/javascript/panda/*/`
- Served by JavaScriptMiddleware
- No compilation required
- Hot reloading supported

**Test Environment**:
- Can use either importmaps OR compiled bundles
- Importmaps served by JavaScriptMiddleware (recommended)
- Compiled bundles served by Rack::Static (fallback)
- Auto-compilation if needed

**Production Environment**:
- Uses **compiled bundles** from GitHub releases
- Downloaded via AssetLoader (see `github-asset-distribution.md`)
- Served by Rack::Static from `public/panda-{gem}-assets/`
- Single minified files with integrity checks

### CSS Files

**All Environments**:
- Served by Rack::Static from `public/panda-core-assets/`
- panda-core orchestrates compilation for all modules
- Auto-compilation in test environment
- Timestamp-based filenames for dev/test
- Semantic versioned filenames for production

### Public Assets (Images, Fonts, etc.)

**All Environments**:
- Served by Rack::Static from `public/panda-{gem}-assets/`
- Static files bundled with each gem
- No compilation required

## Request Flow Examples

### JavaScript Module Request

**Request**: `GET /panda/cms/admin/slug_controller.js`

**Flow**:
1. Request hits Rails middleware stack
2. JavaScriptMiddleware (before Propshaft) intercepts request
3. Strips `/panda/` → `cms/admin/slug_controller.js`
4. Checks panda-core: `app/javascript/panda/cms/admin/slug_controller.js` → Not found
5. Checks panda-cms: `app/javascript/panda/cms/admin/slug_controller.js` → **Found**
6. Reads file content
7. Serves with `Content-Type: application/javascript; charset=utf-8`
8. Adds cache control based on environment

**Headers Sent**:
```
HTTP/1.1 200 OK
Content-Type: application/javascript; charset=utf-8
Content-Length: 2543
Cache-Control: no-cache, no-store, must-revalidate  # (dev/test)
# OR
Cache-Control: public, max-age=31536000  # (production)
```

### CSS Request

**Request**: `GET /panda-core-assets/panda-core-1762886534.css`

**Flow**:
1. Request hits Rails middleware stack
2. Rack::Static (panda-core, before Propshaft) intercepts request
3. Checks if URL starts with `/panda-core-assets/`
4. Serves from `panda-core/public/panda-core-assets/panda-core-1762886534.css`
5. Adds cache control headers

### Public Asset Request

**Request**: `GET /panda-cms-assets/panda-cms-0.10.1.js` (compiled bundle)

**Flow**:
1. Request hits Rails middleware stack
2. Rack::Static (panda-cms) intercepts request
3. Checks if URL starts with `/panda-cms-assets/`
4. Serves from `panda-cms/public/panda-cms-assets/panda-cms-0.10.1.js`

## Middleware Stack Order

Critical importance of middleware order:

```ruby
# Correct order (panda-core engine.rb):
app.config.middleware.insert_before Propshaft::Server, Rack::Static, ...
app.config.middleware.insert_before Propshaft::Server, JavaScriptMiddleware
```

**Why This Order Matters**:

1. **Before Propshaft**: Propshaft intercepts requests for asset pipeline files. Our middleware must run first to catch `/panda/*` requests.

2. **Multiple Rack::Static Issue** (Solved by JavaScriptMiddleware):
   - **Old Approach**: Each gem had `Rack::Static` with `urls: ["/panda"]`
   - **Problem**: First Rack::Static to not find a file would return 404, blocking subsequent middleware
   - **Example Failure**:
     - Request: `/panda/core/application.js`
     - CMS's Rack::Static checks first, doesn't find Core files
     - Returns 404 and blocks request
     - Core's Rack::Static never gets called
   - **Solution**: Single JavaScriptMiddleware checks all modules before returning 404

## Adding Asset Support to New Gems

### Step 1: Register with ModuleRegistry

Add registration at the end of your engine file:

```ruby
# In your-gem/lib/your_gem/engine.rb

# Register with panda-core for asset compilation
Panda::Core::ModuleRegistry.register(
  gem_name: "your-gem",
  engine: "YourGem::Engine",
  paths: {
    views: "app/views/your_gem/**/*.erb",
    components: "app/components/your_gem/**/*.rb"
    # JavaScript paths auto-discovered from config/importmap.rb
  }
)
```

### Step 2: Set Up Public Assets Middleware

Add Rack::Static for your public assets:

```ruby
# In your-gem/lib/your_gem/engine.rb

class Engine < ::Rails::Engine
  isolate_namespace YourGem

  initializer "your_gem.static_assets" do |app|
    # Serve public assets (CSS, images, compiled bundles)
    # JavaScript modules are served by panda-core's JavaScriptMiddleware
    app.config.middleware.use Rack::Static,
      urls: ["/your-gem-assets"],
      root: YourGem::Engine.root.join("public")
  end
end
```

### Step 3: Organize JavaScript Files

Follow the `/panda/` namespace pattern:

```
your-gem/
├── app/
│   └── javascript/
│       └── panda/
│           └── your_gem/          # Matches gem name
│               ├── application.js
│               └── controllers/
│                   ├── example_controller.js
│                   └── another_controller.js
```

**Importmap Setup**:
```ruby
# your-gem/config/importmap.rb

# Your gem's JavaScript modules
pin "panda/your_gem/application", to: "panda/your_gem/application.js"
pin "panda/your_gem/controllers/example_controller", to: "panda/your_gem/controllers/example_controller.js"
```

**Access in Browser**:
- `https://yourapp.com/panda/your_gem/application.js`
- `https://yourapp.com/panda/your_gem/controllers/example_controller.js`

### Step 4: Public Assets Directory

Create public assets directory:

```
your-gem/
├── public/
│   └── your-gem-assets/
│       ├── your-gem-0.1.0.js     # Compiled bundle (production)
│       ├── your-gem-0.1.0.css    # Compiled CSS (optional)
│       └── images/               # Images, fonts, etc.
```

### Step 5: Auto-Compilation (Optional)

If you have CSS to compile, add auto-compilation initializer:

```ruby
# In your-gem/lib/your_gem/engine.rb

initializer "your_gem.auto_compile_css", after: :load_config_initializers do |app|
  next unless Rails.env.test? || ENV["YOUR_GEM_AUTO_COMPILE"] == "true"

  timestamp = Time.now.to_i
  assets_dir = YourGem::Engine.root.join("public", "your-gem-assets")
  timestamped_css = assets_dir.join("your-gem-#{timestamp}.css")

  # Check if CSS already exists
  existing_css = Dir[assets_dir.join("your-gem-*.css")].reject { |f| File.symlink?(f) }

  if existing_css.empty?
    warn "🎨 [Your Gem] Auto-compiling CSS..."

    # Get content paths from ModuleRegistry (includes YOUR gem + all other registered gems)
    content_paths = Panda::Core::ModuleRegistry.tailwind_content_paths
    content_flags = content_paths.map { |path| "--content '#{path}'" }.join(" ")

    # Compile CSS
    input_file = YourGem::Engine.root.join("app/assets/tailwind/application.css")
    cmd = "bundle exec tailwindcss -i #{input_file} -o #{timestamped_css} #{content_flags} --minify"

    _, stderr, status = Open3.capture3(cmd)

    if status.success?
      warn "🎨 [Your Gem] CSS compilation successful (#{timestamped_css.size} bytes)"
    else
      warn "🎨 [Your Gem] CSS compilation failed: #{stderr}"
    end
  end
end
```

## Environment-Specific Behavior

### Development Environment

**JavaScript**:
- ✅ Individual ES modules via importmaps
- ✅ Served by JavaScriptMiddleware
- ✅ Hot reloading
- ✅ No compilation needed

**CSS**:
- ✅ Can use auto-compilation with timestamp filenames
- ✅ Served by Rack::Static
- ✅ Cache disabled (`no-cache, no-store, must-revalidate`)

**Cache Control**:
- JavaScript: `no-cache, no-store, must-revalidate`
- CSS: `no-cache, no-store, must-revalidate`

### Test Environment

**JavaScript**:
- ✅ Individual ES modules via importmaps (recommended)
- ✅ Served by JavaScriptMiddleware
- ✅ Auto-compilation of bundles if needed
- ✅ Timestamp-based filenames for cache busting

**CSS**:
- ✅ Auto-compilation on first boot
- ✅ Timestamp-based filenames (`panda-core-1762886534.css`)
- ✅ Served by Rack::Static

**Cache Control**:
- JavaScript: `no-cache, no-store, must-revalidate`
- CSS: `no-cache, no-store, must-revalidate`

### Production Environment

**JavaScript**:
- ✅ Compiled bundles from GitHub releases
- ✅ Downloaded by AssetLoader
- ✅ Served by Rack::Static
- ✅ Semantic versioned filenames (`panda-cms-0.10.1.js`)
- ✅ Minified with integrity hashes

**CSS**:
- ✅ Compiled bundles from GitHub releases
- ✅ Semantic versioned filenames (`panda-core-0.9.3.css`)
- ✅ Minified and optimized

**Cache Control**:
- JavaScript: `public, max-age=31536000` (1 year)
- CSS: `public, max-age=31536000` (1 year)

## Debugging Asset Loading

### Check Middleware Stack

```bash
# In Rails console
Rails.application.config.middleware.each do |middleware|
  puts "#{middleware.name}"
end
```

Look for:
- `Panda::Core::ModuleRegistry::JavaScriptMiddleware` (before Propshaft)
- `Rack::Static` instances for panda-core-assets, panda-cms-assets

### Check ModuleRegistry

```ruby
# In Rails console
Panda::Core::ModuleRegistry.modules
# => {"panda-core" => {...}, "panda-cms" => {...}}

# Check Tailwind content paths
Panda::Core::ModuleRegistry.tailwind_content_paths
# => ["panda-core/app/views/**/*.erb", "panda-cms/app/views/**/*.erb", ...]

# Check JavaScript paths
Panda::Core::ModuleRegistry.javascript_paths
# => {"panda-core" => [...], "panda-cms" => [...]}
```

### Test JavaScript Serving

```bash
# Start Rails server
bundle exec rails server

# Test JavaScript request
curl -I http://localhost:3000/panda/cms/admin/slug_controller.js

# Should return:
# HTTP/1.1 200 OK
# Content-Type: application/javascript; charset=utf-8
```

### Enable Debug Logging

Add to your test or development environment:

```ruby
# In spec/support/system_test_setup.rb or config/environments/development.rb

# Log middleware requests
Panda::Core::ModuleRegistry::JavaScriptMiddleware.class_eval do
  def call(env)
    puts "[JavaScriptMiddleware] Request: #{env['PATH_INFO']}"
    super
  end
end
```

## Common Issues and Solutions

### Issue: JavaScript 404 Not Found

**Symptoms**:
- Browser shows 404 for `/panda/cms/admin/slug_controller.js`
- JavaScript controllers not loading

**Solutions**:

1. **Check file exists**:
   ```bash
   ls app/javascript/panda/cms/admin/slug_controller.js
   ```

2. **Check ModuleRegistry registration**:
   ```ruby
   Panda::Core::ModuleRegistry.modules.keys
   # Should include "panda-cms"
   ```

3. **Check middleware order**:
   ```ruby
   Rails.application.config.middleware.each { |m| puts m.name }
   # JavaScriptMiddleware should appear before Propshaft::Server
   ```

### Issue: CSS Not Compiling

**Symptoms**:
- 404 for `/panda-core-assets/panda-core-*.css`
- Styles not loading

**Solutions**:

1. **Manually trigger compilation**:
   ```bash
   cd panda-core
   bundle exec rake panda:core:assets:compile
   ```

2. **Check Tailwind content paths**:
   ```ruby
   Panda::Core::ModuleRegistry.tailwind_content_paths
   # Should include paths from all registered gems
   ```

3. **Check public directory**:
   ```bash
   ls panda-core/public/panda-core-assets/
   # Should show panda-core-*.css files
   ```

### Issue: Multiple Rack::Static Blocking Each Other

**Symptoms**:
- Some modules' JavaScript files return 404
- Works for one gem but not another

**This is solved by JavaScriptMiddleware!** If you see this:

1. **Verify you're using JavaScriptMiddleware**:
   ```ruby
   # Check middleware stack
   Rails.application.config.middleware.each { |m| puts m.name }
   # Should show JavaScriptMiddleware, NOT multiple Rack::Static for /panda
   ```

2. **Remove old Rack::Static for JavaScript**:
   ```ruby
   # OLD (Don't do this):
   app.config.middleware.use Rack::Static,
     urls: ["/panda/cms"],
     root: Panda::CMS::Engine.root.join("app/javascript")

   # NEW (Correct):
   # JavaScript is served by panda-core's JavaScriptMiddleware
   # Only serve public assets:
   app.config.middleware.use Rack::Static,
     urls: ["/panda-cms-assets"],
     root: Panda::CMS::Engine.root.join("public")
   ```

## Performance Considerations

### Development

- **No compilation overhead** - ES modules loaded directly
- **Fast refreshes** - Changes visible immediately
- **No caching** - Fresh files every request

### Test

- **One-time compilation** - Auto-compiles on first boot
- **Cached between runs** - Compiled files persist
- **Fast test startup** - No recompilation unless files missing

### Production

- **Pre-compiled assets** - Downloaded from GitHub releases
- **Long-term caching** - 1 year cache headers
- **CDN delivery** - Served via GitHub's CDN
- **Minimal runtime overhead** - Static file serving only

## Summary

The Panda asset serving architecture provides:

- **Unified JavaScript serving** via ModuleRegistry and JavaScriptMiddleware
- **Automatic gem discovery** via self-registration pattern
- **Scalable design** that supports unlimited Panda gems
- **Environment-aware behavior** for optimal dev/test/prod experience
- **No blocking issues** from multiple middleware instances
- **Automatic CSS compilation** with Tailwind content aggregation

For production asset distribution details, see [`github-asset-distribution.md`](github-asset-distribution.md).
