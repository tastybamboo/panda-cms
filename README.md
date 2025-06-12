# Panda CMS

> [!CAUTION]
> This application is being developed in public. It is not ready for production use. If you'd like to try it out (or help with documentation), please contact [@jfi](https://github.com/jfi) by emailing [bamboo@pandacms.io](mailto:bamboo@pandacms.io).

## Panda CMS is the CMS we always wanted. 🐼

Better websites, on Rails.

[Read more about the project...](https://github.com/pandacms/.github/blob/main/profile/README.md) ✨

🐼 is grown from our work at [Otaina](https://www.otaina.co.uk), a small group of freelancers. We needed something that could handle websites large and small – but where we could expand it too. We sent our first websites live in March 2024.

![Gem Version](https://img.shields.io/gem/v/panda-cms) ![Build Status](https://img.shields.io/github/actions/workflow/status/tastybamboo/panda-cms/ci.yml)
![GitHub Last Commit](https://img.shields.io/github/last-commit/tasty-bamboo/panda-cms) [![Ruby Code Style](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/standardrb/standard)

## Usage

### New applications

To create a new Rails app, run the command below, replacing `demo` with the name of the application you want to create:

```
rails new demo $(curl -fsSL https://raw.githubusercontent.com/tastybamboo/generator/main/.railsrc) -m https://raw.githubusercontent.com/tastybamboo/generator/main/template.rb
```

`cd` into your directory (e.g. `demo`), and you'll see `rails db:migrate` and `rails db:seed` have already been run for you.

Then run `bin/dev`. You'll see a basic website has automatically been created for you at http://localhost:3000/

The easiest way for you to get started is to visit http://localhost:3000/admin and login with your GitHub credentials. As the first user, you'll automatically have an administrator account created.

When you're ready to configure further, you can set your own configuration in `config/initializers/panda/cms.rb`. Make sure to turn off the default `github` account creation options!

### Existing applications

Add the following to `Gemfile`:

```ruby
gem "panda-cms"
```

For initial setup, run:

```shell
bundle install
rails generate panda_cms:install
rails panda_cms:install:migrations
rails db:seed
```

You may want to check this does not re-run any of your existing seeds!

If you don't want to use GitHub to login (or are at a URL other than http://localhost:3000/), you'll need to configure a user provider (in `config/initializers/panda/cms.rb`), and then set your user's `admin` attribute to `true` once you've first tried to login.

## Gotchas

This is a non-exhuastive list (there will be many more):

* To date, this has only been tested with Rails 7.1, 7.2 and 8.0
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

## License

The gem is available as open source under the terms of the [BSD-3-Clause License](https://opensource.org/licenses/bsd-3-clause).

Copyright © 2024 - 2025, Panda Software Limited.
