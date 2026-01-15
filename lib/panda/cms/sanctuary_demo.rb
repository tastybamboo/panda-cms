# frozen_string_literal: true

module Panda
  module CMS
    #
    # The Panda Sanctuary Demo Site Generator
    #
    # Creates a comprehensive demo website themed as a panda wildlife sanctuary.
    # This demo exercises all major CMS features including:
    # - Hierarchical pages with multiple templates
    # - Blog posts with EditorJS content
    # - Forms with various field types
    # - Menus (static and auto-generated)
    # - SEO fields
    # - Redirects
    #
    # Usage:
    #   Panda::CMS::SanctuaryDemo.generate!
    #
    class SanctuaryDemo
      attr_accessor :templates, :pages, :menus, :forms, :posts, :users

      def initialize
        @templates = {}
        @pages = {}
        @menus = {}
        @forms = {}
        @posts = []
        @users = {}
      end

      def self.generate!
        new.generate!
      end

      def generate!
        puts "Generating The Panda Sanctuary demo site..."

        create_demo_users
        create_templates
        create_pages
        Panda::CMS::Template.generate_missing_blocks
        create_block_contents
        create_menus
        create_forms
        create_posts
        create_redirects

        puts "Demo site generated successfully!"
        puts "Users: #{@users.count}"
        puts "Templates: #{@templates.count}"
        puts "Pages: #{@pages.count}"
        puts "Forms: #{@forms.count}"
        puts "Posts: #{@posts.count}"

        self
      end

      private

      def create_demo_users
        puts "  Creating demo users..."

        # Create demo admin user
        @users[:admin] = Panda::Core::User.find_or_create_by!(email: "admin@pandasanctuary.example") do |user|
          user.name = "Sarah Chen"
          user.admin = true
          user.image_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=SarahChen"
        end

        # Create demo editor user
        @users[:editor] = Panda::Core::User.find_or_create_by!(email: "editor@pandasanctuary.example") do |user|
          user.name = "James Wilson"
          user.admin = true
          user.image_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=JamesWilson"
        end

        # Create demo contributor
        @users[:contributor] = Panda::Core::User.find_or_create_by!(email: "contributor@pandasanctuary.example") do |user|
          user.name = "Emily Zhang"
          user.admin = false
          user.image_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=EmilyZhang"
        end
      end

      def create_templates
        puts "  Creating templates..."

        template_configs = [
          {name: "Sanctuary Homepage", file_path: "layouts/sanctuary_homepage", max_uses: 1},
          {name: "Sanctuary Page", file_path: "layouts/sanctuary_page"},
          {name: "Sanctuary Gallery", file_path: "layouts/sanctuary_gallery"},
          {name: "Sanctuary Post", file_path: "layouts/sanctuary_post"},
          {name: "Sanctuary Contact", file_path: "layouts/sanctuary_contact", max_uses: 1}
        ]

        template_configs.each do |config|
          key = config[:name].parameterize.underscore.to_sym
          @templates[key] = Panda::CMS::Template.find_or_create_by!(
            name: config[:name],
            file_path: config[:file_path]
          )
          @templates[key].update!(max_uses: config[:max_uses]) if config[:max_uses]
        end
      end

      def create_pages
        puts "  Creating pages..."

        # Home page
        @pages[:home] = create_page(
          path: "/",
          title: "The Panda Sanctuary",
          template: @templates[:sanctuary_homepage],
          seo_title: "The Panda Sanctuary | Home of Giant and Red Pandas",
          seo_description: "Visit The Panda Sanctuary - home to giant and red pandas. Experience conservation in action, adopt a panda, and support wildlife preservation.",
          og_title: "The Panda Sanctuary",
          og_description: "Home to 24 giant and red pandas. Visit us and experience conservation in action."
        )

        # About section
        @pages[:about] = create_page(
          path: "/about",
          title: "About Us",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          seo_description: "Learn about The Panda Sanctuary's mission to protect and conserve pandas and their natural habitats."
        )

        @pages[:about_mission] = create_page(
          path: "/about/mission",
          title: "Our Mission",
          template: @templates[:sanctuary_page],
          parent: @pages[:about],
          seo_description: "Our mission is to protect giant and red pandas through conservation, research, and education."
        )

        @pages[:about_history] = create_page(
          path: "/about/history",
          title: "History",
          template: @templates[:sanctuary_page],
          parent: @pages[:about],
          seo_description: "Founded in 1989, The Panda Sanctuary has been protecting pandas for over 35 years."
        )

        @pages[:about_team] = create_page(
          path: "/about/team",
          title: "Our Team",
          template: @templates[:sanctuary_page],
          parent: @pages[:about],
          seo_description: "Meet the dedicated team of conservationists, keepers, and researchers at The Panda Sanctuary."
        )

        @pages[:about_contact] = create_page(
          path: "/about/contact",
          title: "Contact Us",
          template: @templates[:sanctuary_contact],
          parent: @pages[:about],
          seo_description: "Get in touch with The Panda Sanctuary. Find our address, phone numbers, and contact form."
        )

        # Our Pandas section
        @pages[:our_pandas] = create_page(
          path: "/our-pandas",
          title: "Our Pandas",
          template: @templates[:sanctuary_gallery],
          parent: @pages[:home],
          seo_description: "Meet our family of giant and red pandas. Learn about each panda's personality, history, and conservation story."
        )

        @pages[:giant_pandas] = create_page(
          path: "/our-pandas/giant-pandas",
          title: "Giant Pandas",
          template: @templates[:sanctuary_gallery],
          parent: @pages[:our_pandas],
          seo_description: "Meet our giant pandas - the iconic black and white bears native to China's bamboo forests."
        )

        @pages[:red_pandas] = create_page(
          path: "/our-pandas/red-pandas",
          title: "Red Pandas",
          template: @templates[:sanctuary_gallery],
          parent: @pages[:our_pandas],
          seo_description: "Discover our red pandas - the adorable, raccoon-like mammals from the Himalayan mountains."
        )

        # Visit section
        @pages[:visit] = create_page(
          path: "/visit",
          title: "Plan Your Visit",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          seo_description: "Plan your visit to The Panda Sanctuary. Find opening hours, ticket prices, and directions."
        )

        @pages[:visit_hours] = create_page(
          path: "/visit/hours",
          title: "Opening Hours",
          template: @templates[:sanctuary_page],
          parent: @pages[:visit],
          seo_description: "The Panda Sanctuary opening hours. We're open 7 days a week, 362 days a year."
        )

        @pages[:visit_tickets] = create_page(
          path: "/visit/tickets",
          title: "Tickets & Prices",
          template: @templates[:sanctuary_page],
          parent: @pages[:visit],
          seo_description: "Book tickets to The Panda Sanctuary. Adult, child, family, and annual pass options available."
        )

        @pages[:visit_getting_here] = create_page(
          path: "/visit/getting-here",
          title: "Getting Here",
          template: @templates[:sanctuary_page],
          parent: @pages[:visit],
          seo_description: "Directions to The Panda Sanctuary by car, train, and bus. Free parking available."
        )

        @pages[:visit_accessibility] = create_page(
          path: "/visit/accessibility",
          title: "Accessibility",
          template: @templates[:sanctuary_page],
          parent: @pages[:visit],
          seo_description: "Accessibility information for The Panda Sanctuary. Wheelchair access, facilities, and assistance."
        )

        # Education section
        @pages[:education] = create_page(
          path: "/education",
          title: "Education",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          seo_description: "Educational programmes at The Panda Sanctuary. School visits, resources, and learning opportunities."
        )

        @pages[:education_school_visits] = create_page(
          path: "/education/school-visits",
          title: "School Visits",
          template: @templates[:sanctuary_page],
          parent: @pages[:education],
          seo_description: "Book a school visit to The Panda Sanctuary. Curriculum-linked workshops for all ages."
        )

        @pages[:education_resources] = create_page(
          path: "/education/resources",
          title: "Learning Resources",
          template: @templates[:sanctuary_page],
          parent: @pages[:education],
          seo_description: "Free educational resources about pandas, conservation, and wildlife. Worksheets, videos, and activities."
        )

        @pages[:education_virtual_tours] = create_page(
          path: "/education/virtual-tours",
          title: "Virtual Tours",
          template: @templates[:sanctuary_page],
          parent: @pages[:education],
          seo_description: "Take a virtual tour of The Panda Sanctuary. Live panda cams and 360° experiences."
        )

        # Conservation section
        @pages[:conservation] = create_page(
          path: "/conservation",
          title: "Conservation",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          seo_description: "Conservation efforts at The Panda Sanctuary. Protecting pandas and their habitats worldwide."
        )

        @pages[:conservation_projects] = create_page(
          path: "/conservation/projects",
          title: "Our Projects",
          template: @templates[:sanctuary_page],
          parent: @pages[:conservation],
          seo_description: "Current conservation projects at The Panda Sanctuary. Habitat restoration, breeding programmes, and research."
        )

        @pages[:conservation_research] = create_page(
          path: "/conservation/research",
          title: "Research",
          template: @templates[:sanctuary_page],
          parent: @pages[:conservation],
          seo_description: "Scientific research at The Panda Sanctuary. Contributing to global panda conservation knowledge."
        )

        @pages[:conservation_partners] = create_page(
          path: "/conservation/partners",
          title: "Partners",
          template: @templates[:sanctuary_page],
          parent: @pages[:conservation],
          seo_description: "Our conservation partners. Working together to protect pandas across the globe."
        )

        # Support pages
        @pages[:adopt] = create_page(
          path: "/adopt",
          title: "Adopt a Panda",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          seo_description: "Adopt a panda and support our conservation work. Choose from giant or red panda adoption packages."
        )

        @pages[:donate] = create_page(
          path: "/donate",
          title: "Donate",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          seo_description: "Support The Panda Sanctuary with a donation. Help us protect pandas for future generations."
        )

        # News/Posts page
        @pages[:news] = create_page(
          path: "/news",
          title: "News & Updates",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          page_type: "posts",
          seo_description: "Latest news and updates from The Panda Sanctuary. Panda births, conservation wins, and events."
        )

        # Error pages (hidden)
        @pages[:not_found] = create_page(
          path: "/404",
          title: "Page Not Found",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          status: "hidden"
        )

        @pages[:server_error] = create_page(
          path: "/500",
          title: "Something Went Wrong",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          status: "hidden"
        )

        # Credits page for image attributions
        @pages[:credits] = create_page(
          path: "/credits",
          title: "Image Credits",
          template: @templates[:sanctuary_page],
          parent: @pages[:home],
          seo_description: "Photo credits and attributions for images used on The Panda Sanctuary website."
        )

        # Rebuild nested set after all pages created
        Panda::CMS::Page.reset_column_information
        Panda::CMS::Page.rebuild!
      end

      def create_page(attributes)
        template = attributes.delete(:template)
        parent = attributes.delete(:parent)
        path = attributes[:path]

        page = Panda::CMS::Page.find_or_initialize_by(path: path)
        page.assign_attributes(attributes)
        page.panda_cms_template_id = template&.id
        page.parent = parent
        page.status ||= "active"
        page.save!
        page
      end

      def create_block_contents
        puts "  Creating block contents..."

        # Homepage content
        set_block_content(@pages[:home], :hero_title, "Welcome to The Panda Sanctuary")
        set_block_content(@pages[:home], :hero_subtitle, "Home to 24 magnificent giant and red pandas. Experience conservation in action and help protect these incredible creatures for generations to come.")
        set_block_content(@pages[:home], :featured_title, "Discover Our Sanctuary")
        set_block_content(@pages[:home], :featured_description, "From meeting our pandas to learning about conservation, there's something for everyone at The Panda Sanctuary.")
        set_rich_text_content(@pages[:home], :main_content, homepage_main_content)

        # About page content
        set_rich_text_content(@pages[:about], :main_content, about_main_content)

        # Our Pandas page content
        set_block_content(@pages[:our_pandas], :intro_text, "Get to know the wonderful pandas that call our sanctuary home. Each one has their own unique personality and story.")
        set_rich_text_content(@pages[:our_pandas], :main_content, our_pandas_content)

        # Visit page content
        set_rich_text_content(@pages[:visit], :main_content, visit_content)

        # Conservation content
        set_rich_text_content(@pages[:conservation], :main_content, conservation_content)

        # Adopt page content
        set_rich_text_content(@pages[:adopt], :main_content, adopt_content)

        # Credits page content
        set_rich_text_content(@pages[:credits], :main_content, credits_content)
      end

      def set_block_content(page, key, content)
        return unless page

        block = Panda::CMS::Block.find_by(
          panda_cms_template_id: page.panda_cms_template_id,
          key: key.to_s
        )

        return unless block

        block_content = Panda::CMS::BlockContent.find_or_initialize_by(
          panda_cms_page_id: page.id,
          panda_cms_block_id: block.id
        )
        block_content.content = content
        block_content.save!
      end

      def set_rich_text_content(page, key, html_content)
        return unless page

        block = Panda::CMS::Block.find_by(
          panda_cms_template_id: page.panda_cms_template_id,
          key: key.to_s
        )

        return unless block

        block_content = Panda::CMS::BlockContent.find_or_initialize_by(
          panda_cms_page_id: page.id,
          panda_cms_block_id: block.id
        )
        block_content.content = html_content
        block_content.save!
      end

      def create_menus
        puts "  Creating menus..."

        # Main navigation menu (auto-generated from home page)
        @menus[:main] = Panda::CMS::Menu.find_or_create_by!(name: "Main Menu")
        @menus[:main].update!(kind: :auto, start_page: @pages[:home], depth: 1)
        @menus[:main].generate_auto_menu_items

        # Footer menu (static)
        @menus[:footer] = Panda::CMS::Menu.find_or_create_by!(name: "Footer Menu")
        @menus[:footer].update!(kind: :static)

        # Add footer menu items
        footer_items = [
          {text: "Privacy Policy", page: nil, external_url: "/privacy", sort_order: 1},
          {text: "Terms & Conditions", page: nil, external_url: "/terms", sort_order: 2},
          {text: "Accessibility", page: @pages[:visit_accessibility], external_url: nil, sort_order: 3},
          {text: "Contact", page: @pages[:about_contact], external_url: nil, sort_order: 4}
        ]

        footer_items.each do |item|
          Panda::CMS::MenuItem.find_or_create_by!(
            panda_cms_menu_id: @menus[:footer].id,
            text: item[:text]
          ) do |mi|
            mi.page = item[:page]
            mi.external_url = item[:external_url]
            mi.sort_order = item[:sort_order]
          end
        end
      end

      def create_forms
        puts "  Creating forms..."

        # Contact form
        @forms[:contact] = Panda::CMS::Form.find_or_create_by!(name: "Contact Form")
        if @forms[:contact].new_record?
          @forms[:contact].update(
            description: "General enquiries contact form",
            completion_path: "/about/contact?submitted=true",
            notification_emails: '["info@pandasanctuary.example"]',
            notification_subject: "New contact form submission"
          )
        end

        contact_fields = [
          {name: "name", label: "Name", field_type: "text", required: true, position: 1, active: true},
          {name: "email", label: "Email", field_type: "email", required: true, position: 2, active: true},
          {name: "subject", label: "Subject", field_type: "select", required: true, position: 3, active: true,
           options: ["General Enquiry", "Visiting Information", "Panda Adoption", "Education & School Visits", "Press & Media", "Other"].to_json},
          {name: "message", label: "Message", field_type: "textarea", required: true, position: 4, active: true}
        ]

        contact_fields.each do |field_attrs|
          Panda::CMS::FormField.find_or_create_by!(
            form_id: @forms[:contact].id,
            name: field_attrs[:name]
          ) do |field|
            field.assign_attributes(field_attrs)
          end
        end

        # School visit request form
        @forms[:school_visit] = Panda::CMS::Form.find_or_create_by!(name: "School Visit Request")
        @forms[:school_visit].update!(
          description: "Request form for school visits",
          completion_path: "/education/school-visits?submitted=true",
          notification_emails: '["education@pandasanctuary.example"]',
          notification_subject: "New school visit request",
          send_confirmation: true,
          confirmation_subject: "Your school visit request has been received",
          confirmation_email_field: "contact_email",
          status: "active"
        )

        school_fields = [
          {name: "school_name", label: "School Name", field_type: "text", required: true, position: 1, active: true},
          {name: "contact_name", label: "Contact Name", field_type: "text", required: true, position: 2, active: true},
          {name: "contact_email", label: "Contact Email", field_type: "email", required: true, position: 3, active: true},
          {name: "contact_phone", label: "Contact Phone", field_type: "phone", required: true, position: 4, active: true},
          {name: "preferred_date", label: "Preferred Date", field_type: "date", required: true, position: 5, active: true},
          {name: "alternative_date", label: "Alternative Date", field_type: "date", required: false, position: 6, active: true},
          {name: "number_of_students", label: "Number of Students", field_type: "number", required: true, position: 7, active: true},
          {name: "age_group", label: "Age Group", field_type: "select", required: true, position: 8, active: true,
           options: ["Key Stage 1 (5-7 years)", "Key Stage 2 (7-11 years)", "Key Stage 3 (11-14 years)", "Key Stage 4 (14-16 years)", "Sixth Form/College"].to_json},
          {name: "additional_information", label: "Additional Information", field_type: "textarea", required: false, position: 9, active: true}
        ]

        school_fields.each do |field_attrs|
          Panda::CMS::FormField.find_or_create_by!(
            form_id: @forms[:school_visit].id,
            name: field_attrs[:name]
          ) do |field|
            field.assign_attributes(field_attrs)
          end
        end

        # Adoption enquiry form
        @forms[:adoption] = Panda::CMS::Form.find_or_create_by!(name: "Adoption Enquiry")
        @forms[:adoption].update!(
          description: "Panda adoption enquiry form",
          completion_path: "/adopt?submitted=true",
          notification_emails: '["adoptions@pandasanctuary.example"]',
          notification_subject: "New adoption enquiry",
          status: "active"
        )

        adoption_fields = [
          {name: "name", label: "Name", field_type: "text", required: true, position: 1, active: true},
          {name: "email", label: "Email", field_type: "email", required: true, position: 2, active: true},
          {name: "phone", label: "Phone", field_type: "phone", required: false, position: 3, active: true},
          {name: "panda_preference", label: "Panda Preference", field_type: "select", required: false, position: 4, active: true,
           options: ["No preference", "Mei Mei (Giant Panda)", "Bao Bao (Giant Panda)", "Ling Ling (Giant Panda)", "Rusty (Red Panda)", "Scarlet (Red Panda)", "Maple (Red Panda)"].to_json},
          {name: "package", label: "Package", field_type: "select", required: true, position: 5, active: true,
           options: ["Bronze (£35/year)", "Silver (£60/year)", "Gold (£100/year)", "Platinum (£250/year)"].to_json},
          {name: "gift_adoption", label: "Gift Adoption?", field_type: "checkbox", required: false, position: 6, active: true},
          {name: "message", label: "Message", field_type: "textarea", required: false, position: 7, active: true}
        ]

        adoption_fields.each do |field_attrs|
          Panda::CMS::FormField.find_or_create_by!(
            form_id: @forms[:adoption].id,
            name: field_attrs[:name]
          ) do |field|
            field.assign_attributes(field_attrs)
          end
        end
      end

      def create_posts
        puts "  Creating blog posts..."

        post_data = [
          {
            title: "Meet Our Newest Arrival: Baby Panda Mei Mei",
            slug_date: 3.days.ago,
            status: "active",
            content: mei_mei_post_content,
            seo_description: "We're thrilled to announce the birth of Mei Mei, our newest giant panda cub born at The Panda Sanctuary."
          },
          {
            title: "Conservation Success: Wild Panda Population Update",
            slug_date: 1.week.ago,
            status: "active",
            content: conservation_post_content,
            seo_description: "New census data shows encouraging growth in wild giant panda populations, with our conservation efforts playing a key role."
          },
          {
            title: "Behind the Scenes: A Day in the Life of a Panda Keeper",
            slug_date: 2.weeks.ago,
            status: "active",
            content: keeper_post_content,
            seo_description: "Join us as we follow head keeper Sarah through a typical day caring for our pandas at the sanctuary."
          },
          {
            title: "Bamboo Forest Expansion Project Complete",
            slug_date: 3.weeks.ago,
            status: "active",
            content: bamboo_post_content,
            seo_description: "We've completed our bamboo forest expansion, adding 2 hectares of new habitat for our giant pandas."
          },
          {
            title: "Virtual Panda Cams Now Live 24/7",
            slug_date: 1.month.ago,
            status: "active",
            content: webcam_post_content,
            seo_description: "Watch our pandas live anytime with our new 24/7 panda cam streaming service."
          },
          {
            title: "Summer Events Programme Announced",
            slug_date: 5.weeks.ago,
            status: "draft",
            content: events_post_content,
            seo_description: "Check out our exciting lineup of summer events including keeper talks, feeding sessions, and family activities."
          }
        ]

        post_data.each do |data|
          slug = "/#{data[:slug_date].strftime("%Y/%m")}/#{data[:title].parameterize}"

          post = Panda::CMS::Post.find_or_initialize_by(slug: slug)
          post.title = data[:title]
          post.status = data[:status]
          post.content = data[:content]
          post.cached_content = render_editorjs_content(data[:content])
          post.published_at = (data[:status] == "active") ? data[:slug_date] : nil
          post.seo_description = data[:seo_description]

          # Assign demo user as author
          post.user = @users[:admin] unless post.user_id
          post.author = @users[:admin] unless post.author_id

          post.save!

          @posts << post
        end
      end

      def create_redirects
        puts "  Creating redirects..."

        redirects = [
          {origin_path: "/pandas", destination_path: "/our-pandas"},
          {origin_path: "/animals", destination_path: "/our-pandas"},
          {origin_path: "/contact", destination_path: "/about/contact"},
          {origin_path: "/tickets", destination_path: "/visit/tickets"},
          {origin_path: "/book", destination_path: "/visit/tickets"},
          {origin_path: "/directions", destination_path: "/visit/getting-here"},
          {origin_path: "/schools", destination_path: "/education/school-visits"},
          {origin_path: "/blog", destination_path: "/news"}
        ]

        redirects.each do |redirect|
          Panda::CMS::Redirect.find_or_create_by!(
            origin_path: redirect[:origin_path],
            destination_path: redirect[:destination_path],
            status_code: 301
          )
        end
      end

      # Content helper methods

      def homepage_main_content
        <<~HTML
          <h2>About The Panda Sanctuary</h2>
          <p>Founded in 1989, The Panda Sanctuary has been at the forefront of panda conservation for over 35 years. Our sanctuary is home to 24 incredible pandas – both giant pandas and red pandas – and serves as a vital centre for breeding, research, and education.</p>
          <p>Every visit to our sanctuary directly supports our conservation work, helping protect pandas in the wild and ensuring these magnificent creatures thrive for generations to come.</p>
          <h3>What Makes Us Special</h3>
          <ul>
            <li><strong>Conservation Focus</strong> – We're not just a visitor attraction. Every pound spent here goes directly towards panda conservation.</li>
            <li><strong>Award-Winning Care</strong> – Our keepers are world-renowned experts in panda husbandry and welfare.</li>
            <li><strong>Education First</strong> – We inspire the next generation of conservationists through our schools programme.</li>
            <li><strong>Research Hub</strong> – Our research contributes to global understanding of panda behaviour and reproduction.</li>
          </ul>
        HTML
      end

      def about_main_content
        <<~HTML
          <p>The Panda Sanctuary was founded with a simple but ambitious mission: to protect pandas and inspire people to care about wildlife conservation.</p>
          <p>What started as a small breeding facility in 1989 has grown into one of the world's most respected panda conservation centres. Today, we're home to 18 giant pandas and 6 red pandas, and we've successfully bred 12 cubs since opening.</p>
          <h2>Our Values</h2>
          <ul>
            <li><strong>Conservation</strong> – Everything we do is driven by our commitment to protecting pandas in the wild.</li>
            <li><strong>Welfare</strong> – The wellbeing of our pandas always comes first.</li>
            <li><strong>Education</strong> – We believe knowledge inspires action.</li>
            <li><strong>Community</strong> – Conservation works best when everyone is involved.</li>
          </ul>
          <h2>Accreditations</h2>
          <p>We're proud members of the European Association of Zoos and Aquaria (EAZA) and participate in the global Giant Panda Species Survival Plan.</p>
        HTML
      end

      def our_pandas_content
        <<~HTML
          <h2>A Family of Pandas</h2>
          <p>Each of our pandas has their own unique personality. Some are playful and mischievous, others are calm and contemplative. What they all share is an incredible capacity to capture hearts.</p>
          <p>Our giant pandas spend most of their day eating bamboo – up to 38 kg per day! Our red pandas are more active, often seen climbing and exploring their treetop habitats.</p>
          <h3>Adoption Programme</h3>
          <p>Want to support your favourite panda? Our adoption programme lets you contribute directly to their care while receiving exclusive updates and benefits.</p>
        HTML
      end

      def visit_content
        <<~HTML
          <h2>Everything You Need to Know</h2>
          <p>Planning a visit to The Panda Sanctuary? Here's all the information you need to make the most of your day.</p>
          <h3>Getting Here</h3>
          <p>We're located in Greenwood Valley, just 45 minutes from the city centre. Free parking is available for all visitors.</p>
          <ul>
            <li><strong>By Car</strong> – Follow the A123 and look for brown tourist signs to "Panda Sanctuary"</li>
            <li><strong>By Train</strong> – Greenwood Station is a 15-minute walk, or catch the sanctuary shuttle bus</li>
            <li><strong>By Bus</strong> – Route 45 stops directly outside our main entrance</li>
          </ul>
          <h3>Facilities</h3>
          <ul>
            <li>Café serving hot and cold food</li>
            <li>Gift shop with panda-themed souvenirs</li>
            <li>Baby changing facilities</li>
            <li>Accessible toilets throughout</li>
            <li>Wheelchair and mobility scooter hire</li>
          </ul>
        HTML
      end

      def conservation_content
        <<~HTML
          <h2>Protecting Pandas for the Future</h2>
          <p>Conservation is at the heart of everything we do. Our work extends far beyond our sanctuary walls, supporting panda protection efforts around the world.</p>
          <h3>Our Impact</h3>
          <ul>
            <li><strong>12 cubs born</strong> through our breeding programme</li>
            <li><strong>500 hectares</strong> of bamboo forest protected in China</li>
            <li><strong>50+ research papers</strong> published by our science team</li>
            <li><strong>100,000 students</strong> reached through education programmes</li>
          </ul>
          <h3>Current Projects</h3>
          <p>We're currently working on several exciting initiatives:</p>
          <ul>
            <li><strong>Habitat Corridors</strong> – Connecting fragmented panda habitats in China</li>
            <li><strong>Climate Research</strong> – Understanding how climate change affects bamboo forests</li>
            <li><strong>Community Conservation</strong> – Working with local communities to reduce human-wildlife conflict</li>
          </ul>
        HTML
      end

      def adopt_content
        <<~HTML
          <h2>Adopt a Panda Today</h2>
          <p>By adopting one of our pandas, you'll be directly supporting their care and contributing to vital conservation work.</p>
          <h3>What You'll Receive</h3>
          <ul>
            <li>Official adoption certificate</li>
            <li>Photo of your adopted panda</li>
            <li>Fact sheet about your panda</li>
            <li>Quarterly email updates</li>
            <li>10% discount in our gift shop</li>
          </ul>
          <h3>Adoption Packages</h3>
          <table>
            <thead>
              <tr>
                <th>Package</th>
                <th>Price</th>
                <th>Benefits</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Bronze</td>
                <td>£35/year</td>
                <td>Certificate, photo, updates</td>
              </tr>
              <tr>
                <td>Silver</td>
                <td>£60/year</td>
                <td>Bronze + soft toy, shop discount</td>
              </tr>
              <tr>
                <td>Gold</td>
                <td>£100/year</td>
                <td>Silver + free entry for two</td>
              </tr>
              <tr>
                <td>Platinum</td>
                <td>£250/year</td>
                <td>Gold + keeper experience day</td>
              </tr>
            </tbody>
          </table>
        HTML
      end

      def credits_content
        <<~HTML
          <h2>Credits & Acknowledgments</h2>
          <p>The Panda Sanctuary would like to thank the many individuals and organizations who support our mission to protect and conserve giant pandas.</p>
          
          <h3>Photography Credits</h3>
          <p>All panda images on this website are used under the <a href="https://unsplash.com/license" target="_blank" class="text-green-700 underline">Unsplash License</a>. We are grateful to these talented photographers for making their beautiful panda photography freely available:</p>
          
          <div class="mt-6 space-y-4">
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda on Wood</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@barkernotbaker" target="_blank" class="text-green-700 underline">James Barker</a> on <a href="https://unsplash.com/photos/white-and-black-panda-on-wood-QbRbkNM4-kk" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda on Tree Trunk</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@milesnoble" target="_blank" class="text-green-700 underline">Miles Noble</a> on <a href="https://unsplash.com/photos/panda-bear-on-tree-trunk-Fmkf0HZPPsQ" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda Relaxing on Rock</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@manseok" target="_blank" class="text-green-700 underline">Manseok</a> on <a href="https://unsplash.com/photos/white-and-black-panda-relaxing-on-rock-94c2BwxqwXw" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda on Bamboo Sticks</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@barkernotbaker" target="_blank" class="text-green-700 underline">James Barker</a> on <a href="https://unsplash.com/photos/panda-bear-sitting-on-bamboo-sticks-surrounded-with-trees-NsNRu6dfRds" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Two Pandas on Floor</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@jennyuenoherrero" target="_blank" class="text-green-700 underline">Jenny Ueno Herrero</a> on <a href="https://unsplash.com/photos/two-white-and-black-pandas-lying-on-floor-during-daytime-4EajIuUxgAQ" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda on Gray Plank</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@neom" target="_blank" class="text-green-700 underline">NEOM</a> on <a href="https://unsplash.com/photos/panda-bear-on-gray-plank-near-green-plant-GYpsSWHslHA" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda on Tree</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@_pablomerchanm" target="_blank" class="text-green-700 underline">Pablo Merchán Montes</a> on <a href="https://unsplash.com/photos/panda-on-tree-1o8VV8yOw40" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda Eating Plant</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@raghav_arumugam" target="_blank" class="text-green-700 underline">Raghav Arumugam</a> on <a href="https://unsplash.com/photos/panda-eating-plant-6DSID8Ey9-U" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda on Tree Branch</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@chuttersnap" target="_blank" class="text-green-700 underline">CHUTTERSNAP</a> on <a href="https://unsplash.com/photos/panda-bear-on-brown-tree-branch-during-daytime-qgpLJ1T8KeA" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Panda on Wooden Fence</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@giancescon" target="_blank" class="text-green-700 underline">Gian Cescon</a> on <a href="https://unsplash.com/photos/white-and-black-panda-on-brown-wooden-fence-during-daytime-e3mu-MTj7Xk" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
            
            <div class="border-l-4 border-green-600 pl-4">
              <p class="font-semibold">Walking Panda</p>
              <p class="text-sm text-gray-600">Photo by <a href="https://unsplash.com/@codyboard" target="_blank" class="text-green-700 underline">Cody Board</a> on <a href="https://unsplash.com/photos/walking-panda-front-of-concrete-building-fFO5DsFV5gk" target="_blank" class="text-green-700 underline">Unsplash</a></p>
            </div>
          </div>
          
          <p class="mt-6 text-sm text-gray-600"><em>All images are used under the Unsplash License, which allows free use for commercial and non-commercial purposes without requiring permission. We provide attribution as a courtesy to these wonderful photographers.</em></p>
          
          <h3 class="mt-8">Our Team</h3>
          <p>Our dedicated team of veterinarians, conservationists, and keepers work tirelessly to provide the best care for our pandas and advance panda conservation efforts.</p>
          
          <h3>Conservation Partners</h3>
          <p>We are grateful for our partnerships with leading conservation organizations around the world, including international panda research institutions and wildlife protection agencies.</p>
          
          <h3>Supporters & Donors</h3>
          <p>This work would not be possible without the generous support of our donors, sponsors, and volunteers. Thank you for believing in panda conservation.</p>
        HTML
      end

      # Blog post content (EditorJS JSON format)

      def mei_mei_post_content
        {
          time: Time.current.to_i * 1000,
          blocks: [
            {
              type: "header",
              data: {text: "A Special Announcement", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "We are absolutely thrilled to announce the birth of <b>Mei Mei</b>, our newest giant panda cub! Born on #{3.days.ago.strftime("%B %d")}, Mei Mei weighed just 150 grams at birth – about the size of a stick of butter."}
            },
            {
              type: "paragraph",
              data: {text: "Mother Ling Ling and baby are both doing exceptionally well. Our veterinary team is monitoring them closely, and we're delighted to report that Mei Mei is feeding well and gaining weight every day."}
            },
            {
              type: "header",
              data: {text: "The First Few Days", level: 3}
            },
            {
              type: "paragraph",
              data: {text: "Giant panda cubs are among the smallest mammal newborns relative to their mother's size. At birth, Mei Mei was about 1/900th of Ling Ling's weight! She'll grow quickly though – by six months, she could weigh over 20 kg."}
            },
            {
              type: "paragraph",
              data: {text: "For now, Mei Mei spends most of her time sleeping and nursing. Her eyes won't open for another 6-8 weeks, and she won't start crawling for about three months."}
            },
            {
              type: "header",
              data: {text: "What This Means for Conservation", level: 3}
            },
            {
              type: "paragraph",
              data: {text: "Every panda birth is precious. With fewer than 2,000 giant pandas remaining in the wild, successful breeding in conservation centres like ours is vital for the species' survival."}
            },
            {
              type: "paragraph",
              data: {text: "Mei Mei is the 12th cub born at The Panda Sanctuary, and she represents hope for the future of her species."}
            }
          ],
          version: "2.28.2"
        }.to_json
      end

      def conservation_post_content
        {
          time: Time.current.to_i * 1000,
          blocks: [
            {
              type: "paragraph",
              data: {text: "The latest census data from China has revealed encouraging news: the wild giant panda population has grown by 17% over the past decade, with an estimated 1,864 individuals now living in their natural habitat."}
            },
            {
              type: "header",
              data: {text: "A Collaborative Success", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "This success is the result of decades of collaborative conservation work between sanctuaries like ours, Chinese authorities, and local communities. Key factors include:"}
            },
            {
              type: "list",
              data: {
                style: "unordered",
                items: [
                  "Expansion and connection of protected reserves",
                  "Successful breeding and reintroduction programmes",
                  "Community engagement and sustainable development",
                  "Anti-poaching enforcement"
                ]
              }
            },
            {
              type: "header",
              data: {text: "Our Contribution", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "The Panda Sanctuary has contributed to this success through our breeding programme, scientific research, and by funding habitat protection in China's Sichuan province."}
            },
            {
              type: "paragraph",
              data: {text: "While we celebrate this milestone, we know there's still work to do. Climate change threatens the bamboo forests that pandas depend on, and habitat fragmentation remains a challenge."}
            }
          ],
          version: "2.28.2"
        }.to_json
      end

      def keeper_post_content
        {
          time: Time.current.to_i * 1000,
          blocks: [
            {
              type: "paragraph",
              data: {text: "Ever wondered what it's like to care for pandas every day? We followed head keeper Sarah Chen through a typical day at the sanctuary."}
            },
            {
              type: "header",
              data: {text: "6:00 AM - Early Start", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "\"I arrive before the pandas wake up,\" Sarah explains. \"The first job is always a health check. I observe each panda, looking for any changes in behaviour or appetite.\""}
            },
            {
              type: "header",
              data: {text: "7:30 AM - Breakfast Time", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "Each panda gets approximately 30-40 kg of fresh bamboo daily. \"We source bamboo from three different species to provide variety,\" says Sarah. \"It takes about two hours just to prepare breakfast!\""}
            },
            {
              type: "header",
              data: {text: "10:00 AM - Enrichment Activities", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "Mental stimulation is crucial for panda welfare. Sarah hides treats in puzzle feeders, introduces new scents, and rotates toys to keep our pandas engaged."}
            },
            {
              type: "header",
              data: {text: "The Rewarding Part", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "\"The best part of my job? Knowing that the work we do here contributes to saving a species. Every day I get to help these incredible animals, and that never gets old.\""}
            }
          ],
          version: "2.28.2"
        }.to_json
      end

      def bamboo_post_content
        {
          time: Time.current.to_i * 1000,
          blocks: [
            {
              type: "paragraph",
              data: {text: "We're excited to announce the completion of our bamboo forest expansion project, adding 2 hectares of new habitat for our giant pandas."}
            },
            {
              type: "header",
              data: {text: "Two Years in the Making", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "This project has been two years in the making. We've planted over 10,000 bamboo plants across three different species, creating a naturalistic environment that mimics the pandas' wild habitat."}
            },
            {
              type: "header",
              data: {text: "Benefits for Our Pandas", level: 2}
            },
            {
              type: "list",
              data: {
                style: "unordered",
                items: [
                  "More space to roam and explore",
                  "Greater dietary variety with multiple bamboo species",
                  "Natural terrain including slopes and streams",
                  "Improved breeding conditions"
                ]
              }
            },
            {
              type: "paragraph",
              data: {text: "The new habitat is now open to visitors, offering spectacular viewing opportunities from our elevated walkway."}
            }
          ],
          version: "2.28.2"
        }.to_json
      end

      def webcam_post_content
        {
          time: Time.current.to_i * 1000,
          blocks: [
            {
              type: "paragraph",
              data: {text: "Can't make it to the sanctuary? Now you can watch our pandas anytime, anywhere with our new 24/7 live streaming panda cams."}
            },
            {
              type: "header",
              data: {text: "Four Camera Views", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "We've installed four high-definition cameras throughout our panda enclosures:"}
            },
            {
              type: "list",
              data: {
                style: "ordered",
                items: [
                  "Giant Panda Indoor Den – Watch feeding time and naptime",
                  "Giant Panda Outdoor Habitat – See climbing and playing",
                  "Red Panda Treehouse – Catch our red pandas exploring",
                  "Nursery Cam – When we have cubs, watch them grow"
                ]
              }
            },
            {
              type: "header",
              data: {text: "How to Watch", level: 2}
            },
            {
              type: "paragraph",
              data: {text: "The panda cams are free to access through our website. Simply visit the Virtual Tours section and choose your camera view. You can also chat with other panda fans in our live chat feature."}
            }
          ],
          version: "2.28.2"
        }.to_json
      end

      def events_post_content
        {
          time: Time.current.to_i * 1000,
          blocks: [
            {
              type: "paragraph",
              data: {text: "Get ready for an exciting summer at The Panda Sanctuary! We've put together a fantastic programme of events for all ages."}
            },
            {
              type: "header",
              data: {text: "Highlights", level: 2}
            },
            {
              type: "list",
              data: {
                style: "unordered",
                items: [
                  "Daily keeper talks at 11am and 3pm",
                  "Panda feeding experiences (booking essential)",
                  "Junior Keeper workshops for ages 8-12",
                  "Photography mornings before opening time",
                  "Evening events with prosecco and pandas"
                ]
              }
            },
            {
              type: "paragraph",
              data: {text: "Booking opens on 1st May for members, and 8th May for everyone else."}
            }
          ],
          version: "2.28.2"
        }.to_json
      end

      def render_editorjs_content(json_string)
        data = JSON.parse(json_string)
        data["blocks"].map do |block|
          case block["type"]
          when "header"
            "<h#{block["data"]["level"]}>#{block["data"]["text"]}</h#{block["data"]["level"]}>"
          when "paragraph"
            "<p>#{block["data"]["text"]}</p>"
          when "list"
            tag = (block["data"]["style"] == "ordered") ? "ol" : "ul"
            items = block["data"]["items"].map { |item| "<li>#{item}</li>" }.join
            "<#{tag}>#{items}</#{tag}>"
          else
            ""
          end
        end.join("\n")
      rescue
        ""
      end
    end
  end
end
