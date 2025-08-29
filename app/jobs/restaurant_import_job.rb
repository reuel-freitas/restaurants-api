class RestaurantImportJob < ApplicationJob
  queue_as :default

  def perform(file_path_or_data)
    Rails.logger.info "Starting restaurant import job"

    begin
      service = RestaurantImportService.new(file_path_or_data)
      result = service.import

      if result[:success]
        Rails.logger.info "Restaurant import completed successfully. " \
                         "Restaurants: #{result[:data][:restaurants_processed]}, " \
                         "Menus: #{result[:data][:menus_processed]}, " \
                         "Items: #{result[:data][:items_processed]}, " \
                         "Batches: #{result[:data][:batches_processed]}"

        store_import_results(result)

      else
        Rails.logger.error "Restaurant import failed. Errors: #{result[:errors].join(', ')}"

        store_import_results(result)
      end

    rescue StandardError => e
      Rails.logger.error "Restaurant import job failed with exception: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      error_result = {
        success: false,
        errors: [ "Critical error: #{e.message}" ],
        logs: [],
        data: {
          restaurants_processed: 0,
          menus_processed: 0,
          items_processed: 0,
          batches_processed: 0
        }
      }

      store_import_results(error_result)

      raise
    ensure
      cleanup_temp_file(file_path_or_data)
    end
  end

  private

  def store_import_results(result)
    job_id = self.job_id
    cache_key = "import_results:job:#{job_id}"

    Rails.cache.write(cache_key, result, expires_in: 1.hour)

    status = result[:success] ? "success" : "failed"
    restaurants_count = result[:data][:restaurants_processed]
    menus_count = result[:data][:menus_processed]
    items_count = result[:data][:items_processed]
    batches_count = result[:data][:batches_processed]
    item_logs_count = result[:item_logs]&.length || 0

    Rails.logger.info "Import stored in cache with key #{cache_key}: #{status} - " \
                     "#{restaurants_count} restaurants, #{menus_count} menus, " \
                     "#{items_count} items, #{batches_count} batches, " \
                     "#{item_logs_count} item logs"
  rescue StandardError => e
    Rails.logger.error "Failed to store import results in cache: #{e.message}"
  end

  def cleanup_temp_file(file_path_or_data)
    if file_path_or_data.is_a?(String) && File.exist?(file_path_or_data)
      ImportCleanupService.cleanup_file(file_path_or_data)
    end
  end
end
