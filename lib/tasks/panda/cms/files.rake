# frozen_string_literal: true

namespace :panda do
  namespace :cms do
    namespace :files do
      desc "Purge ALL ActiveStorage data (blobs, attachments, variants) and clear image block references"
      task purge_all: [:environment] do
        unless ENV["CONFIRM"] == "yes"
          puts "This will permanently delete ALL uploaded files."
          puts "Run with CONFIRM=yes to proceed."
          exit 1
        end

        variant_count = ActiveStorage::VariantRecord.count
        ActiveStorage::VariantRecord.delete_all
        puts "Deleted #{variant_count} variant records"

        attachment_count = ActiveStorage::Attachment.count
        ActiveStorage::Attachment.delete_all
        puts "Deleted #{attachment_count} attachment records"

        blob_count = ActiveStorage::Blob.count
        ActiveStorage::Blob.find_each do |blob|
          blob.purge
        end
        puts "Purged #{blob_count} blobs (and their backing files)"

        image_blocks = Panda::CMS::Block.where(kind: :image)
        block_content_count = Panda::CMS::BlockContent
          .where(panda_cms_block_id: image_blocks.select(:id))
          .update_all(content: nil, cached_content: nil)
        puts "Cleared #{block_content_count} image block content references"

        puts "Done."
      end

      desc "Find and optionally purge orphaned blobs (no attachments). Run with CONFIRM=yes to purge."
      task cleanup_orphaned: [:environment] do
        orphaned = ActiveStorage::Blob.left_joins(:attachments)
          .where(active_storage_attachments: {id: nil})

        if orphaned.none?
          puts "No orphaned blobs found."
          next
        end

        puts "Found #{orphaned.count} orphaned blobs:"
        orphaned.find_each do |blob|
          puts "  #{blob.filename} (#{blob.byte_size} bytes, created #{blob.created_at.to_date})"
        end

        if ENV["CONFIRM"] == "yes"
          count = 0
          orphaned.find_each do |blob|
            blob.purge
            count += 1
          end
          puts "Purged #{count} orphaned blobs."
        else
          puts "\nRun with CONFIRM=yes to purge these blobs."
        end
      end

      desc "Find and optionally purge duplicate blobs (same checksum). Keeps oldest. Run with CONFIRM=yes to purge."
      task cleanup_duplicates: [:environment] do
        duplicate_checksums = ActiveStorage::Blob
          .group(:checksum)
          .having("COUNT(*) > 1")
          .pluck(:checksum)

        if duplicate_checksums.empty?
          puts "No duplicate blobs found."
          next
        end

        total_duplicates = 0
        duplicate_checksums.each do |checksum|
          blobs = ActiveStorage::Blob.where(checksum: checksum).order(created_at: :asc)
          keeper = blobs.first
          duplicates = blobs.offset(1)

          puts "Checksum #{checksum}:"
          puts "  Keeping: #{keeper.filename} (id: #{keeper.id}, created #{keeper.created_at.to_date})"
          duplicates.each do |blob|
            puts "  Duplicate: #{blob.filename} (id: #{blob.id}, created #{blob.created_at.to_date})"
            total_duplicates += 1
          end
        end

        if ENV["CONFIRM"] == "yes"
          purged = 0
          duplicate_checksums.each do |checksum|
            blobs = ActiveStorage::Blob.where(checksum: checksum).order(created_at: :asc)
            blobs.offset(1).find_each do |blob|
              blob.purge
              purged += 1
            end
          end
          puts "Purged #{purged} duplicate blobs."
        else
          puts "\nFound #{total_duplicates} duplicate blobs across #{duplicate_checksums.size} checksums."
          puts "Run with CONFIRM=yes to purge duplicates (keeping the oldest of each)."
        end
      end
    end
  end
end
