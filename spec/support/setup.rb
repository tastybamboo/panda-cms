# frozen_string_literal: true

def pause
  $stderr.write "Press enter to continue"
  $stdin.gets
end

def debugit
  # Cuprite-specific debugging method
  page.driver.debug
end
