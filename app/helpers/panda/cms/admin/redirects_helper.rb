# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module RedirectsHelper
        # Highlights segments in destination_path that differ from origin_path.
        # Splits both paths by "/" and wraps changed segments in a colored span.
        def highlight_destination_diff(origin_path, destination_path)
          origin_segments = origin_path.to_s.split("/")
          dest_segments = destination_path.to_s.split("/")

          highlighted = dest_segments.each_with_index.map do |segment, i|
            if origin_segments[i] != segment
              content_tag(:span, segment, class: "text-primary-700 font-medium")
            else
              segment
            end
          end

          safe_join(highlighted, "/")
        end
      end
    end
  end
end
