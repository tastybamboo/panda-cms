module ActionText
  class RichTextVersion < ::PandaCms::Version
    self.table_name = :action_text_rich_text_versions
    self.sequence_name = :action_text_rich_text_versions_id_seq
  end
end