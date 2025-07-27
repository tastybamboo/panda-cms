# frozen_string_literal: true

def pause
  $stderr.write "Press enter to continue"
  $stdin.gets
end

def debugit
  # Selenium doesn't have a built-in debug method
  pause
end
