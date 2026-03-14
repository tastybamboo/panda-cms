prefix = Panda::CMS.config.posts[:prefix]
root = Panda::CMS::Current.root
feed_url = "#{root}/#{prefix}.atom"
posts_url = "#{root}/#{prefix}"
latest_updated = @posts.maximum(:updated_at) || Time.current

xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.feed xmlns: "http://www.w3.org/2005/Atom" do
  xml.title Panda::CMS.config.title || "Blog"
  xml.link href: feed_url, rel: "self", type: "application/atom+xml"
  xml.link href: posts_url, rel: "alternate", type: "text/html"
  xml.id feed_url
  xml.updated latest_updated.iso8601

  @posts.each do |post|
    post_url = post.canonical_url.presence || "#{root}/#{prefix}#{post.slug}"
    published = post.published_at || post.created_at

    xml.entry do
      xml.title post.title
      xml.link href: post_url, rel: "alternate", type: "text/html"
      xml.id post_url
      xml.published published.iso8601
      xml.updated post.updated_at.iso8601
      xml.summary post.excerpt(300), type: "text"
      xml.content post.cached_content, type: "html" if post.cached_content.present?

      if post.author
        xml.author do
          xml.name post.author.name
        end
      end

      if post.post_category
        xml.category term: post.post_category.name
      end
    end
  end
end
