# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Checks for ES6 syntax (const, let, arrow functions) in execute_script and evaluate_script calls
      # which may not be supported in all browser contexts during testing.
      #
      # @example
      #   # bad
      #   page.execute_script("const foo = 1;")
      #   page.evaluate_script("let bar = 2;")
      #   page.execute_script("() => { return true; }")
      #
      #   # good
      #   page.execute_script("var foo = 1;")
      #   page.evaluate_script("var bar = 2;")
      #   page.execute_script("function() { return true; }")
      class NoEs6InJsCalls < Base
        MSG = "Avoid ES6 syntax (%<syntax>s) in %<method>s calls. Use ES5 syntax (var, function) instead."

        ES6_PATTERNS = {
          const: /\bconst\s+/,
          let: /\blet\s+/,
          arrow_function: /=>/
        }.freeze

        def on_send(node)
          return unless js_execution_method?(node)
          return unless node.arguments.any?

          # Check first argument (the JavaScript string)
          js_arg = node.arguments.first
          return unless js_arg.str_type? || js_arg.dstr_type?

          js_code = extract_js_code(js_arg)
          check_for_es6_syntax(node, js_code)
        end

        private

        def js_execution_method?(node)
          %i[execute_script evaluate_script].include?(node.method_name)
        end

        def extract_js_code(node)
          if node.str_type?
            node.source
          elsif node.dstr_type?
            # Handle interpolated strings
            node.source
          else
            ""
          end
        end

        def check_for_es6_syntax(node, js_code)
          ES6_PATTERNS.each do |syntax_name, pattern|
            next unless pattern.match?(js_code)

            add_offense(
              node,
              message: format(
                MSG,
                syntax: syntax_name.to_s.tr("_", " "),
                method: node.method_name
              )
            )
            break # Only report first violation per call
          end
        end
      end
    end
  end
end
