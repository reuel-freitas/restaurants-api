class ImportCleanupService
  def self.cleanup_old_files(hours_old = 24)
    temp_dir = Rails.root.join("tmp", "imports")
    return unless Dir.exist?(temp_dir)

    cutoff_time = hours_old.hours.ago
    files_removed = 0

    Dir.glob(File.join(temp_dir, "import_*")).each do |file_path|
      if File.mtime(file_path) < cutoff_time
        begin
          File.delete(file_path)
          files_removed += 1
          Rails.logger.info "Cleaned up old import file: #{file_path}"
        rescue StandardError => e
          Rails.logger.error "Failed to delete old import file #{file_path}: #{e.message}"
        end
      end
    end

    Rails.logger.info "Import cleanup completed: #{files_removed} files removed"
    files_removed
  end

  def self.cleanup_file(file_path)
    return unless file_path && File.exist?(file_path)

    begin
      File.delete(file_path)
      Rails.logger.info "Cleaned up import file: #{file_path}"
      true
    rescue StandardError => e
      Rails.logger.error "Failed to delete import file #{file_path}: #{e.message}"
      false
    end
  end
end
