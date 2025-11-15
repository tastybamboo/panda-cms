# frozen_string_literal: true

# Base dependencies are now in panda-core (Stimulus, Turbo, Font Awesome, etc.)
# This file only contains CMS-specific pins
# NOTE: Paths must be absolute (starting with /) because Rack::Static serves
# from /panda/cms/, not from asset pipeline /assets/

pin "panda/cms/application", to: "/panda/cms/application.js", preload: true
pin "@hotwired/stimulus-loading", to: "/panda/cms/stimulus-loading.js", preload: true
pin "@editorjs/editorjs", to: "/panda/cms/editor/editorjs.js" # @2.30.6

# Pin the controllers directory
pin "panda/cms/controllers/index", to: "/panda/cms/controllers/index.js"
pin_all_from Panda::CMS::Engine.root.join("app/javascript/panda/cms/controllers"), under: "controllers", to: "/panda/cms/controllers"
pin_all_from Panda::CMS::Engine.root.join("app/javascript/panda/cms/editor"), under: "editor", to: "/panda/cms/editor"
