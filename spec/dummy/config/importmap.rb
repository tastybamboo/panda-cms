# frozen_string_literal: true

# The idea is this file needs nothing explicitly pinned from panda-cms,
# that should all get handled by the engine.rb, etc.

# This just checks that Stimulus can be included without conflicting
pin '@hotwired/stimulus', to: '@hotwired--stimulus.js' # @3.2.2

# This just checks that a normal JS file and Stimulus controllers folder can be included
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'application'
