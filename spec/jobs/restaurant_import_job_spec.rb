require 'rails_helper'

RSpec.describe RestaurantImportJob, type: :job do
  let(:job) { described_class.new }
  let(:file_path) { '/tmp/test_import.csv' }
  let(:json_data) { '{"restaurants": []}' }
  let(:mock_service) { instance_double(RestaurantImportService) }
  let(:success_result) do
    {
      success: true,
      data: {
        restaurants_processed: 5,
        menus_processed: 10,
        items_processed: 50,
        batches_processed: 2
      },
      item_logs: [ 'Item 1 processed', 'Item 2 processed' ],
      errors: []
    }
  end
  let(:failure_result) do
    {
      success: false,
      data: {
        restaurants_processed: 0,
        menus_processed: 0,
        items_processed: 0,
        batches_processed: 0
      },
      item_logs: [],
      errors: [ 'Invalid format', 'Missing required fields' ],
      logs: []
    }
  end

  before do
    allow(RestaurantImportService).to receive(:new).and_return(mock_service)
    allow(Rails.cache).to receive(:write)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    allow(ImportCleanupService).to receive(:cleanup_file)
    allow(File).to receive(:exist?).and_return(false)
    allow(job).to receive(:job_id).and_return('test-job-123')
  end

  describe '#perform' do
    context 'when import is successful' do
      before do
        allow(mock_service).to receive(:import).and_return(success_result)
      end

      it 'processes the import successfully' do
        expect(mock_service).to receive(:import)
        job.perform(file_path)
      end

      it 'logs success information' do
        expect(Rails.logger).to receive(:info).with(
          "Restaurant import completed successfully. " \
          "Restaurants: 5, " \
          "Menus: 10, " \
          "Items: 50, " \
          "Batches: 2"
        )
        job.perform(file_path)
      end

      it 'stores import results' do
        expect(job).to receive(:store_import_results).with(success_result)
        job.perform(file_path)
      end

      it 'logs the start of the job' do
        expect(Rails.logger).to receive(:info).with("Starting restaurant import job")
        job.perform(file_path)
      end
    end

    context 'when import fails' do
      before do
        allow(mock_service).to receive(:import).and_return(failure_result)
      end

      it 'logs error information' do
        expect(Rails.logger).to receive(:error).with(
          "Restaurant import failed. Errors: Invalid format, Missing required fields"
        )
        job.perform(file_path)
      end

      it 'stores import results' do
        expect(job).to receive(:store_import_results).with(failure_result)
        job.perform(file_path)
      end

      it 'logs the start of the job' do
        expect(Rails.logger).to receive(:info).with("Starting restaurant import job")
        job.perform(file_path)
      end
    end

    context 'when an exception occurs' do
      let(:error_message) { 'Service unavailable' }

      before do
        allow(mock_service).to receive(:import).and_raise(StandardError, error_message)
      end

      it 'logs the exception details and re-raises' do
        expect(Rails.logger).to receive(:error).with(
          "Restaurant import job failed with exception: #{error_message}"
        )
        expect(Rails.logger).to receive(:error).with(instance_of(String))
        expect(job).to receive(:store_import_results).with(
          hash_including(
            success: false,
            errors: [ "Critical error: #{error_message}" ],
            data: {
              restaurants_processed: 0,
              menus_processed: 0,
              items_processed: 0,
              batches_processed: 0
            }
          )
        )

        expect { job.perform(file_path) }.to raise_error(StandardError, error_message)
      end

      it 'logs the start of the job before exception' do
        expect(Rails.logger).to receive(:info).with("Starting restaurant import job")
        expect { job.perform(file_path) }.to raise_error(StandardError)
      end

      it 'always calls cleanup_temp_file in ensure block' do
        expect(job).to receive(:cleanup_temp_file).with(file_path)
        expect { job.perform(file_path) }.to raise_error(StandardError)
      end
    end

    context 'when processing JSON data' do
      before do
        allow(mock_service).to receive(:import).and_return(success_result)
      end

      it 'creates service with JSON data' do
        expect(RestaurantImportService).to receive(:new).with(json_data)
        job.perform(json_data)
      end

      it 'does not attempt to clean up JSON data' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.perform(json_data)
      end

      it 'logs the start of the job' do
        expect(Rails.logger).to receive(:info).with("Starting restaurant import job")
        job.perform(json_data)
      end
    end

    context 'when processing file path' do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(mock_service).to receive(:import).and_return(success_result)
      end

      it 'creates service with file path' do
        expect(Rails.logger).to receive(:info).with("Starting restaurant import job")
        expect(RestaurantImportService).to receive(:new).with(file_path)
        job.perform(file_path)
      end

      it 'cleans up the file after processing' do
        expect(ImportCleanupService).to receive(:cleanup_file).with(file_path)
        job.perform(file_path)
      end
    end

    context 'when processing with nil data' do
      before do
        allow(mock_service).to receive(:import).and_return(success_result)
      end

      it 'handles nil data gracefully' do
        expect(RestaurantImportService).to receive(:new).with(nil)
        job.perform(nil)
      end

      it 'does not attempt to clean up nil data' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.perform(nil)
      end
    end

    context 'when processing with empty string' do
      before do
        allow(mock_service).to receive(:import).and_return(success_result)
      end

      it 'handles empty string data gracefully' do
        expect(RestaurantImportService).to receive(:new).with('')
        job.perform('')
      end

      it 'does not attempt to clean up empty string data' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.perform('')
      end
    end

    context 'when processing with symbol data' do
      before do
        allow(mock_service).to receive(:import).and_return(success_result)
      end

      it 'handles symbol data gracefully' do
        expect(RestaurantImportService).to receive(:new).with(:symbol_data)
        job.perform(:symbol_data)
      end

      it 'does not attempt to clean up symbol data' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.perform(:symbol_data)
      end
    end
  end

  describe '#store_import_results' do
    let(:job_id) { 'test-job-123' }
    let(:cache_key) { "import_results:job:#{job_id}" }

    before do
      allow(job).to receive(:job_id).and_return(job_id)
    end

    context 'when storing successful results' do
      it 'writes to cache with correct key and expiration' do
        expect(Rails.cache).to receive(:write).with(cache_key, success_result, expires_in: 1.hour)
        job.send(:store_import_results, success_result)
      end

      it 'logs success information' do
        expect(Rails.logger).to receive(:info).with(
          "Import stored in cache with key #{cache_key}: success - " \
          "5 restaurants, 10 menus, " \
          "50 items, 2 batches, " \
          "2 item logs"
        )
        job.send(:store_import_results, success_result)
      end
    end

    context 'when storing failed results' do
      it 'writes to cache with correct key and expiration' do
        expect(Rails.cache).to receive(:write).with(cache_key, failure_result, expires_in: 1.hour)
        job.send(:store_import_results, failure_result)
      end

      it 'logs failure information' do
        expect(Rails.logger).to receive(:info).with(
          "Import stored in cache with key #{cache_key}: failed - " \
          "0 restaurants, 0 menus, " \
          "0 items, 0 batches, " \
          "0 item logs"
        )
        job.send(:store_import_results, failure_result)
      end
    end

    context 'when result has no item_logs' do
      let(:result_without_logs) do
        {
          success: true,
          data: {
            restaurants_processed: 1,
            menus_processed: 1,
            items_processed: 1,
            batches_processed: 1
          }
        }
      end

      it 'handles missing item_logs gracefully' do
        expect(Rails.logger).to receive(:info).with(
          "Import stored in cache with key #{cache_key}: success - " \
          "1 restaurants, 1 menus, " \
          "1 items, 1 batches, " \
          "0 item logs"
        )
        job.send(:store_import_results, result_without_logs)
      end
    end

    context 'when result has nil item_logs' do
      let(:result_with_nil_logs) do
        {
          success: true,
          data: {
            restaurants_processed: 1,
            menus_processed: 1,
            items_processed: 1,
            batches_processed: 1
          },
          item_logs: nil
        }
      end

      it 'handles nil item_logs gracefully' do
        expect(Rails.logger).to receive(:info).with(
          "Import stored in cache with key #{cache_key}: success - " \
          "1 restaurants, 1 menus, " \
          "1 items, 1 batches, " \
          "0 item logs"
        )
        job.send(:store_import_results, result_with_nil_logs)
      end
    end

    context 'when cache write fails' do
      before do
        allow(Rails.cache).to receive(:write).and_raise(StandardError, 'Cache error')
      end

      it 'logs the error and continues' do
        expect(Rails.logger).to receive(:error).with('Failed to store import results in cache: Cache error')
        expect { job.send(:store_import_results, success_result) }.not_to raise_error
      end
    end

    context 'when cache write fails with different error types' do
      before do
        allow(Rails.cache).to receive(:write).and_raise(RuntimeError, 'Runtime error')
      end

      it 'handles different error types gracefully' do
        expect(Rails.logger).to receive(:error).with('Failed to store import results in cache: Runtime error')
        expect { job.send(:store_import_results, success_result) }.not_to raise_error
      end
    end

    context 'when cache write fails with NoMethodError' do
      before do
        allow(Rails.cache).to receive(:write).and_raise(NoMethodError, 'Method not found')
      end

      it 'handles NoMethodError gracefully' do
        expect(Rails.logger).to receive(:error).with('Failed to store import results in cache: Method not found')
        expect { job.send(:store_import_results, success_result) }.not_to raise_error
      end
    end
  end

  describe '#cleanup_temp_file' do
    context 'when file_path_or_data is a file path' do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
      end

      it 'calls ImportCleanupService.cleanup_file' do
        expect(ImportCleanupService).to receive(:cleanup_file).with(file_path)
        job.send(:cleanup_temp_file, file_path)
      end
    end

    context 'when file_path_or_data is not a string' do
      it 'does not call ImportCleanupService.cleanup_file' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.send(:cleanup_temp_file, json_data)
      end
    end

    context 'when file_path_or_data is a string but file does not exist' do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(false)
      end

      it 'does not call ImportCleanupService.cleanup_file' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.send(:cleanup_temp_file, file_path)
      end
    end

    context 'when file_path_or_data is not a string' do
      let(:non_string_data) { { data: 'test' } }

      it 'does not call ImportCleanupService.cleanup_file' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.send(:cleanup_temp_file, non_string_data)
      end
    end

    context 'when file_path_or_data is nil' do
      it 'does not call ImportCleanupService.cleanup_file' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.send(:cleanup_temp_file, nil)
      end
    end

    context 'when file_path_or_data is a number' do
      it 'does not call ImportCleanupService.cleanup_file' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.send(:cleanup_temp_file, 123)
      end
    end

    context 'when file_path_or_data is a boolean' do
      it 'does not call ImportCleanupService.cleanup_file for true' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.send(:cleanup_temp_file, true)
      end

      it 'does not call ImportCleanupService.cleanup_file for false' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.send(:cleanup_temp_file, false)
      end
    end

    context 'when file_path_or_data is an array' do
      it 'does not call ImportCleanupService.cleanup_file' do
        expect(ImportCleanupService).not_to receive(:cleanup_file)
        job.send(:cleanup_temp_file, [ 'file1', 'file2' ])
      end
    end
  end

  describe 'job configuration' do
    it 'uses default queue' do
      expect(described_class.queue_name).to eq('default')
    end

    it 'inherits from ApplicationJob' do
      expect(described_class).to be < ApplicationJob
    end
  end

  describe 'integration scenarios' do
    context 'complete successful import flow' do
      before do
        allow(mock_service).to receive(:import).and_return(success_result)
        allow(File).to receive(:exist?).with(file_path).and_return(true)
      end

      it 'executes the complete flow without errors' do
        expect(Rails.logger).to receive(:info).with("Starting restaurant import job")
        expect(Rails.logger).to receive(:info).with(
          "Restaurant import completed successfully. " \
          "Restaurants: 5, " \
          "Menus: 10, " \
          "Items: 50, " \
          "Batches: 2"
        )
        expect(ImportCleanupService).to receive(:cleanup_file).with(file_path)

        job.perform(file_path)
      end
    end

    context 'complete failed import flow' do
      before do
        allow(mock_service).to receive(:import).and_return(failure_result)
        allow(File).to receive(:exist?).with(file_path).and_return(true)
      end

      it 'executes the complete flow with error handling' do
        expect(Rails.logger).to receive(:info).with("Starting restaurant import job")
        expect(Rails.logger).to receive(:error).with(
          "Restaurant import failed. Errors: Invalid format, Missing required fields"
        )
        expect(ImportCleanupService).to receive(:cleanup_file).with(file_path)

        job.perform(file_path)
      end
    end

    context 'complete exception flow' do
      before do
        allow(mock_service).to receive(:import).and_raise(StandardError, 'Test error')
        allow(File).to receive(:exist?).with(file_path).and_return(true)
      end

      it 'executes the complete flow with exception handling' do
        expect(Rails.logger).to receive(:info).with("Starting restaurant import job")
        expect(Rails.logger).to receive(:error).with("Restaurant import job failed with exception: Test error")
        expect(Rails.logger).to receive(:error).with(instance_of(String))
        expect(ImportCleanupService).to receive(:cleanup_file).with(file_path)

        expect { job.perform(file_path) }.to raise_error(StandardError, 'Test error')
      end
    end

    context 'complete flow with different data types' do
      it 'handles JSON string data' do
        allow(mock_service).to receive(:import).and_return(success_result)
        expect(RestaurantImportService).to receive(:new).with(json_data)
        expect(ImportCleanupService).not_to receive(:cleanup_file)

        job.perform(json_data)
      end

      it 'handles file path data' do
        allow(mock_service).to receive(:import).and_return(success_result)
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        expect(RestaurantImportService).to receive(:new).with(file_path)
        expect(ImportCleanupService).to receive(:cleanup_file).with(file_path)

        job.perform(file_path)
      end
    end
  end
end
