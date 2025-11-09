class AddSeoFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    # Add SEO basic fields
    add_column :panda_cms_posts, :seo_title, :string
    add_column :panda_cms_posts, :seo_description, :text
    add_column :panda_cms_posts, :seo_keywords, :string

    # Robots control (visible/invisible in base CMS)
    add_column :panda_cms_posts, :seo_index_mode, :enum,
      enum_type: "panda_cms_seo_index_mode",
      default: "visible",
      null: false

    # Canonical URL
    add_column :panda_cms_posts, :canonical_url, :string

    # OpenGraph / Social Sharing
    add_column :panda_cms_posts, :og_title, :string
    add_column :panda_cms_posts, :og_description, :text
    add_column :panda_cms_posts, :og_type, :enum,
      enum_type: "panda_cms_og_type",
      default: "article",  # Posts default to 'article' type
      null: false

    # Note: No inherit_seo for posts - they don't have hierarchy
  end
end
