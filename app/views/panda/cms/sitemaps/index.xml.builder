xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @pages.each do |page|
    xml.url do
      url = page.canonical_url.presence || "#{Panda::CMS::Current.root}#{page.path}"
      xml.loc url
      xml.lastmod page.last_updated_at.iso8601
    end
  end

  if Panda::CMS.config.posts[:enabled]
    prefix = Panda::CMS.config.posts[:prefix]
    @posts.each do |post|
      xml.url do
        url = post.canonical_url.presence || "#{Panda::CMS::Current.root}/#{prefix}#{post.slug}"
        xml.loc url
        xml.lastmod post.updated_at.iso8601
      end
    end
  end
end
