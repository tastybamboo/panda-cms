# frozen_string_literal: true

# Base dependencies are now in panda-core (Stimulus, Turbo, Font Awesome, etc.)
# This file only contains CMS-specific pins

pin "application_panda_cms", to: "panda/cms/application_panda_cms.js", preload: true
pin "@hotwired/stimulus-loading", to: "panda/cms/stimulus-loading.js", preload: true
pin "@editorjs/editorjs", to: "panda/cms/editor/editorjs.js" # @2.30.6

# Pin the controllers directory
pin "controllers", to: "panda/cms/controllers/index.js"
pin_all_from Panda::CMS::Engine.root.join("app/javascript/panda/cms/controllers"), under: "controllers"
pin_all_from Panda::CMS::Engine.root.join("app/javascript/panda/cms/editor"), under: "editor"
