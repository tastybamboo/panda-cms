# frozen_string_literal: true

ActionView::Base.field_error_proc = proc do |html_tag, instance|
  html = ""
  form_fields = %w[input select textarea trix-editor label].join(", ")
  error_class = "text-error bg-error border-error border-1 box-shadow-error focus:ring-error focus:border-error "
  message_class = "block w-full text-base p-0 m-0 mt-1 text-error font-semibold"
  autofocused = false

  Nokogiri::HTML::DocumentFragment.parse(html_tag).css(form_fields).each do |element|
    next unless form_fields.include?(element.node_name)

    autofocused ||= true

    message = "#{instance.object.class.human_attribute_name(instance.send(:sanitized_method_name))} "
    message += if instance.error_message.respond_to?(:each)
      "#{instance.error_message.uniq.to_sentence}."
    else
      "#{instance.error_message}."
    end

    if element.node_name.eql?("label")
      html = element.to_s
    else
      element.add_class(error_class)
      html = if element.get_attribute("data-prefix")
        "#{element}</div><div class=\"#{message_class}\">#{message}"
      elsif element.get_attribute("type") != "checkbox"
        "#{element}<div class=\"#{message_class}\">#{message}</div>"
      else
        element.to_s
      end
    end
  end

  html.html_safe
end
