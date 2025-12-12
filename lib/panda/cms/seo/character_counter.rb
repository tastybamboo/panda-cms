# frozen_string_literal: true

module Panda
  module CMS
    module Seo
      # Lightweight helper to mirror the client-side character counter logic
      # and allow deterministic testing.
      class CharacterCounter
        Result = Struct.new(:count, :limit, :remaining, :status, :over_limit?, keyword_init: true)

        DEFAULT_WARNING_THRESHOLD = 10

        def self.evaluate(value, limit:, warning_threshold: DEFAULT_WARNING_THRESHOLD)
          text = value.to_s
          count = text.length
          remaining = limit - count

          status =
            if remaining.negative?
              :error
            elsif remaining < warning_threshold
              :warning
            else
              :ok
            end

          Result.new(
            count: count,
            limit: limit,
            remaining: remaining,
            status: status,
            over_limit?: remaining.negative?
          )
        end
      end
    end
  end
end
