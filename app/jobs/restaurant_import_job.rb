class RestaurantImportJob < ApplicationJob
  queue_as :default

  def perform(json_data)
    Rails.logger.info "Starting restaurant import job"

    begin
      service = RestaurantImportService.new(json_data)
      result = service.import

      if result[:success]
        Rails.logger.info "Restaurant import completed successfully. " \
                         "Restaurants: #{result[:data][:restaurants_processed]}, " \
                         "Menus: #{result[:data][:menus_processed]}, " \
                         "Items: #{result[:data][:items_processed]}"

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
        data: { restaurants_processed: 0, menus_processed: 0, items_processed: 0 }
      }

      store_import_results(error_result)

      raise
    end
  end

  private

  def store_import_results(result)
    # Store results with job ID for easy retrieval
    job_id = provider_job_id || SecureRandom.uuid
    cache_key = "import_results:job:#{job_id}"

    Rails.cache.write(cache_key, result, expires_in: 1.hour)

    status = result[:success] ? "success" : "failed"
    restaurants_count = result[:data][:restaurants_processed]
    menus_count = result[:data][:menus_processed]
    items_count = result[:data][:items_processed]

    Rails.logger.info "Import stored in cache with key #{cache_key}: #{status} - " \
                     "#{restaurants_count} restaurants, #{menus_count} menus, #{items_count} items"
  rescue StandardError => e
    Rails.logger.error "Failed to store import results in cache: #{e.message}"
  end
end
