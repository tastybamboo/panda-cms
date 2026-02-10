# Panda CMS

## Better websites, on Rails. 🐼

A modern, modular content management system built for Ruby on Rails. Simple enough for small sites, powerful enough to scale. No bloat, just the features you need.

Panda CMS has been in production since March 2024 and is actively maintained by [Otaina](https://www.otaina.co.uk).

**[Website](https://tastybamboo.net)** · **[Pro Features](https://tastybamboo.net/pro.html)** · **[Managed Hosting](https://tastybamboo.net/hosting.html)**

![Gem Version](https://img.shields.io/gem/v/panda-cms) ![Build Status](https://img.shields.io/github/actions/workflow/status/tastybamboo/panda-cms/ci.yml)
![GitHub Last Commit](https://img.shields.io/github/last-commit/tastybamboo/panda-cms) [![Ruby Code Style](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/standardrb/standard)

## Usage

### New applications

To create a new Rails app, run the command below, replacing `demo` with the name of the application you want to create:

```
rails new demo $(curl -fsSL https://raw.githubusercontent.com/tastybamboo/generator/main/.railsrc) -m https://raw.githubusercontent.com/tastybamboo/generator/main/template.rb
```

`cd` into your directory (e.g. `demo`), then run `bin/dev`. A basic website has automatically been created for you at http://localhost:3000/

Visit http://localhost:3000/admin and click **Developer Login** to sign in with any name and email. As the first user, you'll automatically be given an administrator account.

For production, configure GitHub OAuth (or another provider) in `config/initializers/panda.rb` — see [Configuration](#configuration) below.

### Existing applications

Add the gem to your `Gemfile`:

```ruby
gem "panda-cms"
```

Then run:

```shell
bundle install
rails generate panda:cms:install
bundle install
rails db:migrate
rails db:seed
```

The install generator will:
- Create `config/initializers/panda.rb` (if it doesn't exist)
- Enable GitHub OAuth and Developer Login authentication
- Add `omniauth-github` to your Gemfile (hence the second `bundle install`)
- Copy all required database migrations

Start your server with `bin/dev` and visit `/admin`. In development, click **Developer Login** to sign in immediately — no OAuth setup needed.

For production, add your GitHub OAuth credentials:

```shell
rails credentials:edit
```

```yaml
github:
  client_id: your_client_id
  client_secret: your_client_secret
```

The CMS engine **auto-mounts itself** — no changes to `config/routes.rb` are needed.

## Configuration

All Panda configuration is managed in `config/initializers/panda.rb`. The install generator creates this file with sensible defaults:

```ruby
# config/initializers/panda.rb
Panda::Core.configure do |config|
  config.admin_path = "/admin"
  config.login_page_title = "Admin"
  config.admin_title = "MyApp Admin"

  config.authentication_providers = {
    github: {
      enabled: true,
      name: "GitHub",
      client_id: Rails.application.credentials.dig(:github, :client_id),
      client_secret: Rails.application.credentials.dig(:github, :client_secret)
    },
    developer: {
      enabled: true,
      name: "Developer Login"
    }
  }

  config.session_token_cookie = :panda_session
  config.user_class = "Panda::Core::User"
  config.user_identity_class = "Panda::Core::UserIdentity"
end

Panda::CMS.configure do |config|
  config.require_login_to_view = false
end
```

### Authentication providers

The **Developer** provider is built into OmniAuth and only appears in development mode. It shows a simple form to enter a name and email — no OAuth app setup needed.

For production, configure one or more OAuth providers. Supported providers:

| Provider | Gem | Config key |
|----------|-----|------------|
| GitHub | `omniauth-github` | `github` |
| Google | `omniauth-google-oauth2` | `google_oauth2` |
| Microsoft | `omniauth-microsoft_graph` | `microsoft_graph` |

Providers without valid credentials are automatically skipped at boot.

See the [Configuration Documentation](docs/developers/configuration/) for detailed information on all available settings.

### Engine Mounting

**The Panda CMS engine automatically mounts itself** via an `after_initialize` hook. You do **not** need to manually add `mount Panda::CMS::Engine => "/"` to your routes file. The engine will:

- Mount itself at the root path
- Add admin routes under the configured admin path (e.g., `/admin/cms` or `/manage/cms`)
- Set up a catch-all route for CMS pages (excluding admin paths)

The admin interface structure will be:
- `{admin_path}` - Panda Core admin dashboard (authentication, profile)
- `{admin_path}/cms` - Panda CMS admin (pages, posts, menus, files)

## Styling

**Panda CMS does not compile or manage its own CSS.** All admin interface styling is provided by [Panda Core](https://github.com/tastybamboo/panda-core).

The CMS automatically loads Core's compiled stylesheet:

```erb
<link rel="stylesheet" href="/panda-core-assets/panda-core.css">
```

Core's Rack middleware serves this file from the gem, so:

- ✅ No CSS copying or compilation needed
- ✅ Styles update automatically when Core updates
- ✅ Consistent design across all Panda gems

For details on customizing styles, development workflows, and troubleshooting, see [docs/STYLING.md](docs/STYLING.md).

For CSS compilation (when contributing to styling), see [Panda Core Asset Compilation Guide](https://github.com/tastybamboo/panda-core/blob/main/docs/ASSET_COMPILATION.md).

## Gotchas

This is a non-exhaustive list (there will be many more):

* To date, this has only been tested with Rails 7.1, 7.2 and 8
* There may be conflicts if you're not using Tailwind CSS on the frontend. Please report this.

## Contributing

We welcome contributions.

See our [Contributing Guidelines](https://docs.pandacms.io/developers/contributing/)

### Testing

Panda CMS uses RSpec for testing.

#### Using Fixtures

We encourage using fixtures for tests instead of factories for consistent test data:

1. Create fixture files in `spec/fixtures` named after the model's table (e.g., `panda_cms_pages.yml`)
2. Define records with unique names and their attributes
3. Use helper methods to create test templates with mocked file validation

Example fixture format:

```yaml
# spec/fixtures/panda_cms_pages.yml
home_page:
  title: "Home"
  path: "/"
  panda_cms_template_id: <%= ActiveRecord::FixtureSet.identify(:page_template) %>
  status: "active"
  created_at: <%= Time.current %>
  updated_at: <%= Time.current %>
```

Example test using fixtures:

```ruby
# Access fixture using table name and record name
page = panda_cms_pages(:home_page)
expect(page.title).to eq("Home")
```

When testing models with file validations or complex callbacks, use the helper methods in `spec/models/panda/cms/page_spec.rb` as a reference.

## 🚀 Running CI Locally

This project uses a **deterministic CI environment**, based on a single Docker
image (`panda-cms-test`). This ensures:

- identical Ruby/Node/Chrome versions everywhere
- no drift between local / Docker / GitHub Actions / act
- fast, stable, reproducible tests

There are **three** supported ways to run the full CI suite locally.

---

### 1. Run full CI via Docker Compose

```sh
bin/ci build      # build the local test image
bin/ci local      # run full CI stack locally
```

This uses `docker-compose.ci.yml` and reproduces the entire GitHub Actions environment.

---

### 2. Run single RSpec execution in the CI container

```sh
bin/ci test
```

This mounts your project into the container and executes RSpec exactly as CI does.

---

### 3. Run GitHub Actions locally using act

Install act:

```sh
brew install act
```

Use the project’s `.actrc`:

```
-P ubuntu-latest=ghcr.io/tastybamboo/panda-cms-test:local
--container-options "--shm-size=2gb"
```

Then run:

```sh
bin/ci act
```

This executes **the real GitHub Actions workflow** on your machine.

---

### 4. Continuous Integration on GitHub

GitHub Actions uses the same deterministic container image.
See:

```
.github/workflows/ci.yml
```

---

### 5. Code Coverage

Coverage is produced per-suite (models, requests, libs, system) and merged
into a unified `coverage/` directory via SimpleCov.

Artifacts are uploaded automatically on CI.

## License

The gem is available as open source under the terms of the [BSD-3-Clause License](https://opensource.org/licenses/bsd-3-clause).

Copyright © 2024 - 2026, Otaina Limited.
