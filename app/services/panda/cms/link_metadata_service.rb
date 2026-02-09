# frozen_string_literal: true

require "net/http"
require "uri"
require "nokogiri"

module Panda
  module CMS
    class LinkMetadataService
      MAX_REDIRECTS = 3
      CONNECT_TIMEOUT = 5
      READ_TIMEOUT = 5
      MAX_RESPONSE_SIZE = 1_048_576 # 1 MB

      def self.call(url)
        new(url).call
      end

      def initialize(url)
        @url = url
      end

      def call
        validate_url!
        html = fetch_html(@url, MAX_REDIRECTS)
        parse_metadata(html)
      end

      private

      def validate_url!
        uri = URI.parse(@url)
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          raise ArgumentError, "Only http and https URLs are allowed"
        end
      rescue URI::InvalidURIError
        raise ArgumentError, "Invalid URL"
      end

      def fetch_html(url, redirects_remaining)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = CONNECT_TIMEOUT
        http.read_timeout = READ_TIMEOUT

        request = Net::HTTP::Get.new(uri.request_uri)
        request["User-Agent"] = "PandaCMS LinkTool/1.0"
        request["Accept"] = "text/html"

        response = http.request(request)

        case response
        when Net::HTTPRedirection
          if redirects_remaining > 0
            location = response["location"]
            # Handle relative redirects
            location = URI.join(url, location).to_s unless location.start_with?("http")
            fetch_html(location, redirects_remaining - 1)
          else
            raise "Too many redirects"
          end
        when Net::HTTPSuccess
          body = response.body.to_s
          if body.bytesize > MAX_RESPONSE_SIZE
            body = body.byteslice(0, MAX_RESPONSE_SIZE)
          end
          body.force_encoding("UTF-8")
        else
          raise "HTTP #{response.code}"
        end
      end

      def parse_metadata(html)
        doc = Nokogiri::HTML(html)

        title = og_content(doc, "og:title") || doc.at_css("title")&.text
        description = og_content(doc, "og:description") ||
          doc.at_css('meta[name="description"]')&.[]("content")
        image_url = og_content(doc, "og:image")

        meta = {
          title: title.to_s.strip.truncate(200),
          description: description.to_s.strip.truncate(500)
        }

        meta[:image] = {url: image_url} if image_url.present?

        meta
      end

      def og_content(doc, property)
        doc.at_css("meta[property='#{property}']")&.[]("content")
      end
    end
  end
end
