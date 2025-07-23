# frozen_string_literal: true

pin "application_panda_cms", to: "panda_cms/application_panda_cms.js", preload: true

pin "@hotwired/turbo", to: "@hotwired--turbo.js", preload: true # @8.0.12
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js", preload: true # @7.2.101
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "panda_cms/stimulus-loading.js", preload: true
pin "tailwindcss-stimulus-components" # @6.1.2
pin "@editorjs/editorjs", to: "panda/cms/editor/editorjs.js" # @2.30.6

# Pin the controllers directory
pin "controllers", to: "panda/cms/controllers/index.js"
pin_all_from Panda::CMS::Engine.root.join("app/javascript/panda/cms/controllers"), under: "controllers"
pin_all_from Panda::CMS::Engine.root.join("app/javascript/panda/cms/editor"), under: "editor"
