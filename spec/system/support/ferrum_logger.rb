# frozen_string_literal: true

class FerrumLogger
  def puts(log_str)
    return unless ENV["DEBUG"]
    return if log_str.nil?

    _log_symbol, _log_time, log_body_str = log_str.to_s.strip.split(" ", 3)
    return if log_body_str.nil?

    begin
      log_body = JSON.parse(log_body_str)
    rescue
      # Don't output raw log strings to prevent duplication
      return
    end

    case log_body["method"]
    when "Runtime.consoleAPICalled"
      log_body["params"]["args"].each do |arg|
        case arg["type"]
        when "string"
          # Only output messages that aren't already prefixed with [Panda CMS]
          next if arg["value"].to_s.start_with?("[Panda CMS]")
          # Skip any values that look like raw JSON
          next if arg["value"].to_s.strip.start_with?("{", "[")
        when "object"
          # Skip object output to avoid raw JSON
          next
        end
      end

    when "Runtime.exceptionThrown"
      # noop, this is already logged because we have "js_errors: true" in cuprite.

    when "Log.entryAdded"
      message = "#{log_body["params"]["entry"]["url"]} - #{log_body["params"]["entry"]["text"]}"
    end
  end
end
