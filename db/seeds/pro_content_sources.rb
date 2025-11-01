# frozen_string_literal: true

# Seed common trusted content sources for Panda CMS Pro
#
# This creates a starting set of content sources with appropriate trust levels
# for academic, medical, and general reference content.

puts "Creating Panda CMS Pro default content sources..."

# Academic and Research Sources - Always Prefer
[
  {domain: "ncbi.nlm.nih.gov", notes: "National Center for Biotechnology Information - PubMed, PMC"},
  {domain: "scholar.google.com", notes: "Google Scholar - Academic papers and citations"},
  {domain: "doi.org", notes: "Digital Object Identifier system - Academic paper links"},
  {domain: "arxiv.org", notes: "arXiv - Preprint repository for scientific papers"}
].each do |source_data|
  Panda::CMS::Pro::ContentSource.find_or_create_by!(domain: source_data[:domain]) do |source|
    source.trust_level = :always_prefer
    source.notes = source_data[:notes]
  end
end

# Medical and Health Sources - Trusted
[
  {domain: "nhs.uk", notes: "UK National Health Service"},
  {domain: "cdc.gov", notes: "US Centers for Disease Control and Prevention"},
  {domain: "who.int", notes: "World Health Organization"},
  {domain: "nih.gov", notes: "US National Institutes of Health"},
  {domain: "mayoclinic.org", notes: "Mayo Clinic - Medical information"},
  {domain: "webmd.com", notes: "WebMD - Health information"},
  {domain: "medicalnewstoday.com", notes: "Medical News Today"}
].each do |source_data|
  Panda::CMS::Pro::ContentSource.find_or_create_by!(domain: source_data[:domain]) do |source|
    source.trust_level = :trusted
    source.notes = source_data[:notes]
  end
end

# Mental Health Specific Sources - Trusted
[
  {domain: "mind.org.uk", notes: "Mind - UK mental health charity"},
  {domain: "rethink.org", notes: "Rethink Mental Illness"},
  {domain: "mentalhealth.org.uk", notes: "Mental Health Foundation"},
  {domain: "samh.org.uk", notes: "Scottish Association for Mental Health"},
  {domain: "nimh.nih.gov", notes: "National Institute of Mental Health (US)"},
  {domain: "nami.org", notes: "National Alliance on Mental Illness (US)"}
].each do |source_data|
  Panda::CMS::Pro::ContentSource.find_or_create_by!(domain: source_data[:domain]) do |source|
    source.trust_level = :trusted
    source.notes = source_data[:notes]
  end
end

# Educational and Reference Sources - Trusted
[
  {domain: "wikipedia.org", notes: "Wikipedia - Verify with primary sources"},
  {domain: "britannica.com", notes: "Encyclopedia Britannica"},
  {domain: "oxforddictionaries.com", notes: "Oxford Dictionaries"},
  {domain: "merriam-webster.com", notes: "Merriam-Webster Dictionary"}
].each do |source_data|
  Panda::CMS::Pro::ContentSource.find_or_create_by!(domain: source_data[:domain]) do |source|
    source.trust_level = :trusted
    source.notes = source_data[:notes]
  end
end

# Government and Official Sources - Trusted
[
  {domain: "gov.uk", notes: "UK Government official website"},
  {domain: "gov.scot", notes: "Scottish Government"},
  {domain: "gov.wales", notes: "Welsh Government"},
  {domain: "nidirect.gov.uk", notes: "Northern Ireland Government"}
].each do |source_data|
  Panda::CMS::Pro::ContentSource.find_or_create_by!(domain: source_data[:domain]) do |source|
    source.trust_level = :trusted
    source.notes = source_data[:notes]
  end
end

# Social Media and User-Generated Content - Untrusted (verify before use)
[
  {domain: "twitter.com", notes: "Social media - verify claims independently"},
  {domain: "x.com", notes: "Social media (Twitter/X) - verify claims independently"},
  {domain: "facebook.com", notes: "Social media - verify claims independently"},
  {domain: "instagram.com", notes: "Social media - verify claims independently"},
  {domain: "tiktok.com", notes: "Social media - verify claims independently"},
  {domain: "reddit.com", notes: "Social media forum - verify claims independently"}
].each do |source_data|
  Panda::CMS::Pro::ContentSource.find_or_create_by!(domain: source_data[:domain]) do |source|
    source.trust_level = :untrusted
    source.notes = source_data[:notes]
  end
end

puts "✓ Created #{Panda::CMS::Pro::ContentSource.count} default content sources"
