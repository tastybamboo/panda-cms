# Contributing to Panda CMS

First off, thank you for considering contributing to Panda CMS! It's people like you that make Panda CMS such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Guidelines](#development-guidelines)
- [Testing](#testing)
- [Code Quality](#code-quality)
- [Submitting Changes](#submitting-changes)
- [License](#license)

## Code of Conduct

This project and everyone participating in it is governed by the [Panda CMS Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [bamboo@pandacms.io](mailto:bamboo@pandacms.io).

## Getting Started

Before you begin:

- Have you read the [code of conduct](CODE_OF_CONDUCT.md)?
- Check out the [existing issues](https://github.com/tastybamboo/panda-cms/issues)
- Read the [README](README.md) to understand the project

### Important Notes

- Panda CMS is currently in active development and not production-ready
- We welcome contributions of all kinds: bug fixes, features, documentation, and tests
- If you're planning a large change, please open an issue first to discuss it

## Development Setup

### Prerequisites

- Ruby 3.0 or later
- PostgreSQL
- Node.js (for asset compilation)
- Git

### Setup Instructions

1. Fork the repository on GitHub
2. Clone your fork locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/panda-cms.git
   cd panda-cms
   ```

3. Install dependencies:

   ```bash
   bundle install
   ```

4. Set up the test database:

   ```bash
   cd spec/dummy
   rails db:create db:migrate
   cd ../..
   ```

5. Run the tests to ensure everything is working:

   ```bash
   bundle exec rspec
   ```

### Running the Development Server

From the project root:

```bash
bin/dev
```

This starts the Rails server on port 3000 and watches for asset changes.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [issue list](https://github.com/tastybamboo/panda-cms/issues) as you might find that you don't need to create one.

When creating a bug report, please include:

- A clear and descriptive title
- Detailed steps to reproduce the problem
- Expected behavior and what actually happened
- Ruby version, Rails version, and OS
- Any relevant logs or error messages
- Screenshots if applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/tastybamboo/panda-cms/issues). When creating an enhancement suggestion:

- Use a clear and descriptive title
- Provide a detailed description of the suggested enhancement
- Explain why this enhancement would be useful
- List any similar features in other projects

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `documentation` - Documentation improvements

### Pull Requests

1. Create a new branch from `main`:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following our [development guidelines](#development-guidelines)

3. Add or update tests as needed

4. Ensure all tests pass:

   ```bash
   bundle exec rspec
   ```

5. Run code quality tools:

   ```bash
   bundle exec standardrb
   bundle exec brakeman --quiet
   bundle exec erb_lint app/views --lint-all
   ```

6. Commit your changes with a descriptive commit message

7. Push to your fork and submit a pull request to the `main` branch

## Development Guidelines

### Architecture

- Panda CMS is a Rails Engine following standard Rails conventions
- All models are under the `Panda::CMS` namespace
- Views use ViewComponent pattern for reusable UI components
- Content editing uses EditorJS for block-based content

### Code Style

- Follow the [StandardRB](https://github.com/standardrb/standard) Ruby style guide
- Use meaningful variable and method names
- Add comments for complex logic
- Keep methods focused and concise

### Model Conventions

- Inherit from `Panda::CMS::ApplicationRecord`
- Use UUIDs as primary keys (configured by default)
- Use nested sets for hierarchical data (pages, menus)
- Store EditorJS content as JSON with cached HTML rendering

### Security

- Never introduce security vulnerabilities (XSS, SQL injection, etc.)
- Sanitize user input appropriately
- Follow Rails security best practices
- Use strong parameters for mass assignment protection

### Dependencies

- Minimize new dependencies where possible
- Document why new dependencies are needed
- Ensure dependencies are actively maintained
- Check for license compatibility (BSD-3-Clause)

## Testing

Panda CMS uses RSpec for testing with a comprehensive test suite.

### Test Types

- **Model specs**: Test business logic and validations
- **System specs**: Test user-facing functionality with browser automation
- **Component specs**: Test ViewComponents

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/panda/cms/page_spec.rb

# Run tests matching a pattern
bundle exec rspec spec/system/ -e "validation"

# Run tests by line number
bundle exec rspec spec/models/panda/cms/page_spec.rb:42
```

### Writing Tests

- Use fixtures instead of factories for consistent test data
- Fixtures are located in `spec/fixtures/`
- Follow existing test patterns in the codebase
- Ensure tests are deterministic and don't depend on order
- System tests use Cuprite (headless Chrome) for browser automation
- See `spec/TEST_WRITING_GUIDE.md` for detailed testing patterns

### Test Coverage

- Aim for comprehensive test coverage of new features
- All bug fixes should include a test that would have caught the bug
- System tests should cover critical user workflows

## Code Quality

Before submitting a pull request, ensure your code passes all quality checks:

### Linting

```bash
# Ruby linting with StandardRB
bundle exec standardrb

# Auto-fix safe violations
bundle exec standardrb --fix

# ERB template linting
bundle exec erb_lint app/views --lint-all
```

### Security Scanning

```bash
# Run Brakeman security scanner
bundle exec brakeman --quiet

# Run bundle audit for vulnerable dependencies
bundle exec bundle-audit --update
```

### YAML Validation

```bash
# Run YAML linter
yamllint -c .yamllint .
```

## Submitting Changes

### Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Example:

```
Add user dashboard to admin interface

Implements the dashboard showing recent activity and quick actions.
Includes tests for all dashboard components.

Fixes #123
```

### Pull Request Process

1. Update the README.md or relevant documentation with details of changes
2. Add entries to CHANGELOG.md if applicable
3. Ensure all CI checks pass (tests, linting, security scans)
4. Request review from maintainers
5. Address any review feedback
6. Once approved, a maintainer will merge your PR

### After Your Pull Request is Merged

- Delete your feature branch (both locally and on GitHub)
- Consider helping review other pull requests
- Celebrate your contribution to open source!

## License

By contributing to Panda CMS, you agree that your contributions will be licensed under the [BSD 3-Clause License](LICENSE).

This means:

- Your contributions will be available under the same BSD 3-Clause License as the project
- You affirm that you have the right to submit the contributions
- You understand that contributions are provided "as is" without warranties

Copyright for contributions will be attributed as follows:

```
Copyright © 2024-2025, Otaina Limited
```

## Questions?

Don't hesitate to ask questions! You can:

- Open an issue for general questions
- Email [@jfi](mailto:james@otaina.co.uk) for private inquiries
- Check the [documentation](https://docs.pandacms.io)

## Thank You!

Your contributions to open source, large or small, make projects like Panda CMS possible. Thank you for taking the time to contribute.
