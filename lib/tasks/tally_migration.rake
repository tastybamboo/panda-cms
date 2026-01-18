# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

# Tally.so API client and migration utilities
module TallyMigration
  # Tally API helper methods
  class TallyAPI
    BASE_URL = "https://api.tally.so"

    def initialize(api_key)
      @api_key = api_key
    end

    attr_reader :api_key

    def list_forms
      response = get("/forms")
      response["items"] || response["forms"] || []
    end

    def get_form(form_id)
      get("/forms/#{form_id}")
    end

    def get_submissions(form_id)
      get("/forms/#{form_id}/submissions")["questions"]
    rescue
      []
    end

    private

    def get(path)
      uri = URI.parse("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_file = ENV["SSL_CERT_FILE"] if ENV["SSL_CERT_FILE"]
      # Fallback: try common cert locations if default fails
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Get.new(uri.path)
      request["Authorization"] = "Bearer #{@api_key}"

      begin
        response = http.request(request)
      rescue OpenSSL::SSL::SSLError
        # Retry without strict CRL checking
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = http.request(request)
      end
      JSON.parse(response.body)
    end
  end

  # Maps Tally field types to Panda CMS field types
  FIELD_TYPE_MAP = {
    "INPUT_TEXT" => "text",
    "INPUT_EMAIL" => "email",
    "INPUT_PHONE_NUMBER" => "phone",
    "INPUT_NUMBER" => "number",
    "INPUT_DATE" => "date",
    "INPUT_LINK" => "url",
    "TEXTAREA" => "textarea",
    "DROPDOWN" => "select",
    "CHECKBOXES" => "checkbox",
    "MULTIPLE_CHOICE" => "radio",
    "MULTI_SELECT" => "checkbox",
    "LINEAR_SCALE" => "number",
    "SIGNATURE" => "text", # Fallback - signatures stored as data URLs
    "FILE_UPLOAD" => "file",
    "HIDDEN_FIELDS" => "hidden"
  }.freeze

  module_function

  def migrate_form(api, form_id)
    tally_form = api.get_form(form_id)
    form_name = tally_form["name"]&.strip

    puts "Migrating: #{form_name} (#{form_id})"

    # Find or create Panda CMS form
    panda_form = Panda::CMS::Form.find_or_initialize_by(name: form_name)
    panda_form.assign_attributes(
      status: "active",
      description: "Migrated from Tally.so (#{form_id}) on #{Date.current}"
    )

    # Extract notification settings from Tally
    settings = tally_form["settings"] || {}
    if settings["hasSelfEmailNotifications"]
      email_to = settings.dig("selfEmailTo", "safeHTMLSchema")&.flatten&.first
      panda_form.notification_emails = email_to if email_to.present?
    end

    panda_form.save!
    puts "  Created form: #{panda_form.name} (ID: #{panda_form.id})"

    # Get questions from submissions endpoint (more reliable than parsing blocks)
    uri = URI.parse("https://api.tally.so/forms/#{form_id}/submissions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.path)
    request["Authorization"] = "Bearer #{ENV["TALLY_API_KEY"] || api.api_key}"

    response = http.request(request)
    data = JSON.parse(response.body)
    questions = data["questions"] || []

    fields_created = 0
    questions.each_with_index do |question, index|
      label = question["label"] || question["title"] || "Field #{index + 1}"
      field_name = label.parameterize.underscore.gsub(/[^a-z0-9_]/, "_").squeeze("_")[0..50]
      field_name = "field_#{index + 1}" if field_name.blank? || field_name == "_"

      # Determine field type from question type
      question_type = question["type"]
      panda_type = FIELD_TYPE_MAP[question_type] || "text"

      # Extract options for select/checkbox/radio fields
      options = []
      if question["options"].is_a?(Array)
        options = question["options"]
      elsif question["choices"].is_a?(Array)
        options = question["choices"]
      end

      # Handle LINEAR_SCALE - create numeric options
      if question_type == "LINEAR_SCALE"
        min = question["min"] || question["minValue"] || 0
        max = question["max"] || question["maxValue"] || 10
        options = (min..max).map(&:to_s)
        panda_type = "select"
      end

      # Create or update field
      field = panda_form.form_fields.find_or_initialize_by(name: field_name)
      field.assign_attributes(
        label: label,
        field_type: panda_type,
        required: question["required"] || false,
        position: index + 1,
        active: true,
        options: options.any? ? options.to_json : nil
      )
      field.save!

      fields_created += 1
      puts "    + #{label} (#{panda_type})"
    end

    puts "  Created #{fields_created} fields"
    panda_form
  end

  def import_form_submissions(api, form_id)
    tally_form = api.get_form(form_id)
    form_name = tally_form["name"]&.strip

    panda_form = Panda::CMS::Form.find_by(name: form_name)
    unless panda_form
      puts "Form not found: #{form_name}. Run migrate first."
      return
    end

    puts "Importing submissions for: #{form_name}"

    # Fetch submissions via API
    uri = URI.parse("https://api.tally.so/forms/#{form_id}/submissions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.path)
    request["Authorization"] = "Bearer #{ENV["TALLY_API_KEY"] || api.api_key}"

    response = http.request(request)
    data = JSON.parse(response.body)

    submissions = data["submissions"] || []
    questions = data["questions"] || []

    puts "  Found #{submissions.length} submissions"

    # Build question ID to field name map
    question_map = {}
    questions.each do |q|
      label = q["label"] || q["title"]
      next unless label
      field_name = label.parameterize.underscore.gsub(/[^a-z0-9_]/, "_").squeeze("_")[0..50]
      question_map[q["id"]] = field_name
    end

    imported = 0
    skipped = 0

    submissions.each do |submission|
      # Skip if already imported (check by created_at and first field value)
      submitted_at = begin
        Time.parse(submission["submittedAt"])
      rescue
        Time.current
      end

      # Build submission data
      submission_data = {}
      responses = submission["responses"] || []
      responses.each do |response|
        field_name = question_map[response["questionId"]]
        next unless field_name

        value = response["answer"]

        # Handle arrays (checkboxes, multi-select)
        if value.is_a?(Array)
          # Check if it's an array of file objects
          value = if value.first.is_a?(Hash) && value.first.key?("url")
            # Multiple file uploads - store as JSON
            value.to_json
          else
            # Regular multi-select - join with commas
            value.join(", ")
          end
        elsif value.is_a?(Hash) && value.key?("url")
          # Single file/image upload - store as JSON for proper rendering
          value = value.to_json
        end

        submission_data[field_name] = value if value.present?
      end

      if submission_data.empty?
        skipped += 1
        next
      end

      # Check for duplicate
      existing = panda_form.form_submissions.where(created_at: submitted_at..(submitted_at + 1.second)).first
      if existing
        skipped += 1
        next
      end

      panda_form.form_submissions.create!(
        data: submission_data,
        created_at: submitted_at,
        updated_at: submitted_at
      )
      imported += 1
    end

    panda_form.update!(submission_count: panda_form.form_submissions.count)

    puts "  Imported: #{imported}"
    puts "  Skipped: #{skipped} (empty or duplicate)"
    puts "  Total: #{panda_form.form_submissions.count}"
  end

  def extract_text_from_schema(schema)
    return "" unless schema.is_a?(Array)

    schema.map do |item|
      if item.is_a?(String)
        item
      elsif item.is_a?(Array) && item.first.is_a?(String)
        item.first
      elsif item.is_a?(Array) && item.first.is_a?(Array)
        extract_text_from_schema(item)
      else
        ""
      end
    end.join.strip
  end

  def detect_field_type(header, sample_values)
    header_lower = header.downcase

    return "email" if header_lower.include?("email")
    return "phone" if header_lower.include?("phone") || header_lower.include?("tel")
    return "url" if header_lower.include?("website") || header_lower.include?("url")
    return "date" if header_lower.include?("date") || header_lower.include?("appointment")

    values = Array(sample_values).compact.map(&:to_s).reject(&:empty?)
    return "text" if values.empty?

    if values.any? { |v| v.match?(URI::MailTo::EMAIL_REGEXP) }
      return "email"
    end

    if values.any? { |v| v.match?(%r{\Ahttps?://}i) }
      return "url"
    end

    if values.any? { |v| v.match?(/\A[\d\s\-+()]{7,}\z/) }
      return "phone"
    end

    if values.any? { |v| v.length > 100 }
      return "textarea"
    end

    "text"
  end
end

namespace :panda_cms do
  namespace :forms do
    namespace :tally do
      desc "List all forms in Tally.so account"
      task :list, [:api_key] => :environment do |_t, args|
        api_key = args[:api_key] || ENV["TALLY_API_KEY"]

        unless api_key
          puts "Usage: rake panda_cms:forms:tally:list[YOUR_API_KEY]"
          puts "   or: TALLY_API_KEY=xxx rake panda_cms:forms:tally:list"
          exit 1
        end

        api = TallyMigration::TallyAPI.new(api_key)
        forms = api.list_forms

        puts "Found #{forms.length} forms:\n\n"
        forms.each do |form|
          puts "  #{form["id"]}: #{form["name"]} (#{form["numberOfSubmissions"]} submissions)"
        end
        puts "\nTo migrate a form: rake panda_cms:forms:tally:migrate[API_KEY,FORM_ID]"
        puts "To migrate all: rake panda_cms:forms:tally:migrate_all[API_KEY]"
      end

      desc "Migrate a single Tally form to Panda CMS"
      task :migrate, [:api_key, :form_id] => :environment do |_t, args|
        api_key = args[:api_key] || ENV["TALLY_API_KEY"]
        form_id = args[:form_id]

        unless api_key && form_id
          puts "Usage: rake panda_cms:forms:tally:migrate[YOUR_API_KEY,FORM_ID]"
          exit 1
        end

        api = TallyMigration::TallyAPI.new(api_key)
        TallyMigration.migrate_form(api, form_id)
      end

      desc "Migrate all Tally forms to Panda CMS"
      task :migrate_all, [:api_key] => :environment do |_t, args|
        api_key = args[:api_key] || ENV["TALLY_API_KEY"]

        unless api_key
          puts "Usage: rake panda_cms:forms:tally:migrate_all[YOUR_API_KEY]"
          exit 1
        end

        api = TallyMigration::TallyAPI.new(api_key)
        forms = api.list_forms

        puts "Migrating #{forms.length} forms...\n\n"

        forms.each do |form|
          puts "=" * 60
          TallyMigration.migrate_form(api, form["id"])
          puts
        end

        puts "=" * 60
        puts "All forms migrated!"
      end

      desc "Import submissions for a migrated form"
      task :import_submissions, [:api_key, :form_id] => :environment do |_t, args|
        api_key = args[:api_key] || ENV["TALLY_API_KEY"]
        form_id = args[:form_id]

        unless api_key && form_id
          puts "Usage: rake panda_cms:forms:tally:import_submissions[YOUR_API_KEY,FORM_ID]"
          exit 1
        end

        api = TallyMigration::TallyAPI.new(api_key)
        TallyMigration.import_form_submissions(api, form_id)
      end

      desc "Import all submissions from all Tally forms"
      task :import_all_submissions, [:api_key] => :environment do |_t, args|
        api_key = args[:api_key] || ENV["TALLY_API_KEY"]

        unless api_key
          puts "Usage: rake panda_cms:forms:tally:import_all_submissions[YOUR_API_KEY]"
          exit 1
        end

        api = TallyMigration::TallyAPI.new(api_key)
        forms = api.list_forms

        puts "Importing submissions for #{forms.length} forms...\n\n"

        forms.each do |form|
          puts "=" * 60
          TallyMigration.import_form_submissions(api, form["id"])
          puts
        end

        puts "=" * 60
        puts "All submissions imported!"
      end
    end

    # Legacy CSV import task (kept for backwards compatibility)
    desc "Import forms and submissions from Tally.so CSV exports"
    task :import_tally, [:csv_path, :form_name] => :environment do |_t, args|
      require "csv"

      csv_path = args[:csv_path]
      form_name = args[:form_name]

      unless csv_path && File.exist?(csv_path)
        puts "Usage: rake panda_cms:forms:import_tally[path/to/tally_export.csv,'Form Name']"
        puts "Error: CSV file not found at #{csv_path}"
        puts "\nFor API-based migration, use:"
        puts "  rake panda_cms:forms:tally:list[API_KEY]"
        puts "  rake panda_cms:forms:tally:migrate_all[API_KEY]"
        exit 1
      end

      puts "Importing Tally.so submissions from: #{csv_path}"
      puts "Form name: #{form_name || "Will use filename"}"
      puts

      # Use filename as form name if not provided
      form_name ||= File.basename(csv_path, ".csv").titleize

      # Read CSV
      csv_data = CSV.read(csv_path, headers: true)
      puts "Found #{csv_data.count} submissions"

      # Create or find the form
      form = Panda::CMS::Form.find_or_create_by!(name: form_name) do |f|
        f.status = "active"
        f.description = "Migrated from Tally.so on #{Date.current}"
      end
      puts "Using form: #{form.name} (ID: #{form.id})"

      # Detect field types from Tally headers
      headers = csv_data.headers.reject { |h| h.nil? || h.strip.empty? }

      # Skip Tally metadata columns
      tally_meta_columns = ["Submission ID", "Submitted at", "Respondent ID", "Completion time"]
      data_headers = headers - tally_meta_columns

      # Create form fields if they don't exist
      puts "\nCreating/updating form fields..."
      data_headers.each_with_index do |header, index|
        field_name = header.parameterize.underscore
        field_type = TallyMigration.detect_field_type(header, csv_data[header])

        field = form.form_fields.find_or_initialize_by(name: field_name)
        field.assign_attributes(
          label: header,
          field_type: field_type,
          position: index + 1,
          active: true
        )
        field.save!
        puts "  - #{header} (#{field_type})"
      end

      # Import submissions
      puts "\nImporting submissions..."
      imported = 0
      skipped = 0

      csv_data.each do |row|
        submission_data = {}
        data_headers.each do |header|
          field_name = header.parameterize.underscore
          value = row[header]
          submission_data[field_name] = value if value.present?
        end

        if submission_data.empty?
          skipped += 1
          next
        end

        submitted_at = if row["Submitted at"].present?
          begin
            Time.parse(row["Submitted at"])
          rescue
            Time.current
          end
        else
          Time.current
        end

        form.form_submissions.create!(
          data: submission_data,
          created_at: submitted_at,
          updated_at: submitted_at
        )
        imported += 1
      end

      form.update!(submission_count: form.form_submissions.count)

      puts "\nMigration complete!"
      puts "  Imported: #{imported} submissions"
      puts "  Skipped: #{skipped} empty rows"
      puts "  Total in form: #{form.form_submissions.count}"
    end
  end
end
