When working with this Rails application:

1. System Tests:

- All system tests use Cuprite (NOT Selenium) as the driver
- Cuprite is already configured in spec/support/cuprite_helpers.rb
- Never attempt to add or configure Selenium
- Do not attempt to run tests directly - instead show me the command I should run
- For system tests, use "system_helper" not "rails_helper"
- There is no "spec_helper", tests are either using "rails_helper" for standard tests, or "system_helper" for system tests

2. Authentication:

- All authentication (admin and user) is already configured via OmniAuth
- Use existing login helpers (login_as_admin, login_as_user) in tests
- No need to set up or modify authentication methods

3. Terminal Commands:

- When shell commands are needed, show them to me rather than executing them
- Format commands clearly so I can run them myself
- Include any relevant environment variables or flags in the commands

4. Code Standards:

- Use StandardRB formatting for Ruby code
- Use double quotes for strings
- All tests are RSpec

5. EditorJS Integration:

- When interacting with EditorJS in tests, simulate real user behavior
- Use Capybara actions (click, fill_in, etc.) rather than EditorJS API calls
- Follow existing patterns in editor_helpers.rb for consistency
- Prefer interacting with visible UI elements over JavaScript manipulation

6. Engines

- The setup is that there are a number of engines which I control, and then a "host" application.
- panda_core has core functionality.
- panda_cms has pages, posts, and editor functionality.
- Some functionality (e.g. UI, menus, ViewComponents) need to move from Panda::CMS to Panda::Core and this hasn't happened yet.
- A host application such as "neurobetter" includes panda_cms as a gem, which then includes panda_core.
- panda_cms and panda_core are open source.
- There will be later paid modules. The first of these is panda_community.
