# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.2] - 2025-11-17

### Changed

- Updated to panda-core v0.10.1 for improved asset handling and authentication

### Added

- SQLite support in CI pipeline with database verification
- Shared system test infrastructure for consistent cross-module testing

### Fixed

- CI asset compilation to match panda-core requirements
- Page form spec test pollution by moving skip to top-level
- JavaScript asset detection to only check for JS files
- JavaScript syntax error by wrapping evaluate_script in IIFE
- about:blank navigation failures in system tests

### Technical Improvements

- Removed legacy asset handling code
- Enhanced test infrastructure reliability
- Improved CI database support and verification

## [0.10.1] - 2025-11-11

### Changed

- Updated to panda-core v0.8.0 with ModuleRegistry for self-registering asset compilation
- CMS now self-registers with panda-core for automatic CSS compilation
- Removed local path reference to panda-core in Gemfile (uses published gem)

### Technical Improvements

- Asset compilation is now orchestrated by panda-core's ModuleRegistry
- Supports private modules without hardcoded knowledge in Core
- Scales automatically to future Panda modules

## [0.10.0] - 2025-11-04

### Changed

- Updated to panda-core v0.6.0 (from v0.4.1) for improved authentication and admin features
- Updated to panda-editor v0.5.0 (from v0.4.0) for enhanced editor functionality

### Added

- New JavaScript controllers: code_editor, inline_code_editor, menu_form, nested_form, tree
- Enhanced file gallery UI with file details view
- Improved menu management with CRUD operations
- Page type field to pages model
- Pending review status for pages and posts
- Cached last updated timestamp for pages
- Favicons and branding assets for dummy app

### Fixed

- Route naming conflict in engine mounting (added :as option to prevent duplicate route names)
- File gallery display and functionality
- Menu item form handling

### Technical Improvements

- Removed local path reference to panda-core (CI compatibility)
- Updated all dependencies in Gemfile.lock
- Auto-fixed StandardRB linting issues
- All tests passing

## [0.8.3] - 2025-11-01

### Added
- Debug utility wrapper module for testing diagnostics

### Changed
- **BREAKING**: Migrated to unified `panda.rb` configuration file (replacing separate `panda_cms.rb` and `panda_editor.rb` files)
- Updated to panda-core v0.4.1 for unified authentication and admin functionality
- Updated to panda-editor v0.4.0 for improved editor integration
- Renamed rake tasks to use consistent `panda:cms` namespace (e.g., `panda:cms:assets:compile`)
- Base admin controller now inherits from `Panda::Core::AdminController` for shared functionality

### Fixed
- Phlex component rendering compatibility with modern Phlex API (v2.3+)
- Phlex component prop accessors throughout panda-cms codebase
- Admin layout navigation to use CMS-specific layout with proper sidebar
- Dashboard redirect to `/admin/cms` after successful login
- JavaScript asset detection to only check for JS files (CSS loaded from Core)
- Test environment to load both compiled CMS bundle and importmap for dependencies
- Removed deprecated `admin_title` configuration option from examples and dummy app

### Technical Improvements
- Centralized admin interface styling in Panda Core for consistency
- Improved OAuth test infrastructure with Redis session store for cross-process testing
- Documented known testing limitations with Capybara cross-process architecture
- Updated test suite to properly skip tests with documented cross-process limitations

## [0.8.2] - 2025-01-XX

### Fixed
- Broken migration that required non-existent service

## [0.8.1] - 2025-01-XX

### Initial Release
- Initial versioned release of Panda CMS
