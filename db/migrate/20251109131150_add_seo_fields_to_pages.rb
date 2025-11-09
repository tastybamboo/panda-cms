class AddSeoFieldsToPages < ActiveRecord::Migration[8.0]
  def change
    # Create enum types for SEO fields
    create_enum :panda_cms_seo_index_mode, ["visible", "invisible"]
    create_enum :panda_cms_og_type, ["website", "article", "profile", "video", "book"]

    # Add SEO basic fields
    add_column :panda_cms_pages, :seo_title, :string
    add_column :panda_cms_pages, :seo_description, :text
    add_column :panda_cms_pages, :seo_keywords, :string

    # Robots control (visible/invisible in base CMS)
    add_column :panda_cms_pages, :seo_index_mode, :enum,
      enum_type: "panda_cms_seo_index_mode",
      default: "visible",
      null: false

    # Canonical URL
    add_column :panda_cms_pages, :canonical_url, :string

    # OpenGraph / Social Sharing
    add_column :panda_cms_pages, :og_title, :string
    add_column :panda_cms_pages, :og_description, :text
    add_column :panda_cms_pages, :og_type, :enum,
      enum_type: "panda_cms_og_type",
      default: "website",
      null: false

    # Inheritance (pages only - they have hierarchy via nested sets)
    add_column :panda_cms_pages, :inherit_seo, :boolean, default: true, null: false
  end
end
