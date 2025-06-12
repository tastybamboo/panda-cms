# frozen_string_literal: true

# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example
has_app_changes = !git.modified_files.grep(/lib/).empty?
has_test_changes = !git.modified_files.grep(/spec/).empty?
is_version_bump = git.modified_files.sort == ["CHANGELOG.md", "lib/panda/cms/version.rb"].sort

warn("Tests were not updated", sticky: false) if has_app_changes && !has_test_changes && !is_version_bump

# Thanks other people!
message(":tada:") if is_version_bump && github.pr_author != "jfi"

# Mainly to encourage writing up some reasoning about the PR, rather than
# just leaving a title
raise "Please provide a summary in the Pull Request description" if github.pr_body.length < 5

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

# Don't let testing shortcuts get into master by accident
raise("fdescribe left in tests") if `grep -r fdescribe spec/ `.length > 1
raise("fit left in tests") if `grep -r fit spec/ `.length > 1

# Lint using reek
reek.lint

# Lint using rubocop (standardrb)
github.dismiss_out_of_range_messages
rubocop.lint inline_comment: true, rubocop_cmd: "standardrb", include_cop_names: true

# Add SimpleCoverage report
simplecov.report "coverage/coverage.json"

# TODOs
todoist.warn_for_todos
todoist.print_todos_table
