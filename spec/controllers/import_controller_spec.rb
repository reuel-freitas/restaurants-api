require 'rails_helper'

RSpec.describe ImportController, type: :controller do
  let(:valid_json_data) do
    {
      'restaurants' => [
        {
          'name' => "Poppo's Cafe",
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 9.00 },
                { 'name' => 'Small Salad', 'price' => 5.00 }
              ]
            }
          ]
        }
      ]
    }
  end

  describe 'POST #create' do
    context 'with valid JSON in request body' do
      it 'enqueues import job successfully' do
        expect(RestaurantImportJob).to receive(:perform_later).with(valid_json_data).and_return(
          double(job_id: 'job_123')
        )

        post :create, body: valid_json_data.to_json, format: :json

        expect(response).to have_http_status(:accepted)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Import job enqueued successfully')
        expect(json_response['job_id']).to eq('job_123')
        expect(json_response['status']).to eq('queued')
        expect(json_response['check_status_command']).to include('job_123')
      end

      it 'returns job information' do
        expect(RestaurantImportJob).to receive(:perform_later).with(valid_json_data).and_return(
          double(job_id: 'job_456')
        )

        post :create, body: valid_json_data.to_json, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['job_id']).to eq('job_456')
        expect(json_response['status']).to eq('queued')
      end
    end

    context 'with invalid JSON' do
      it 'returns bad request for malformed JSON' do
        post :create, body: 'invalid json', format: :json

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Invalid JSON format')
      end

      it 'returns bad request for empty body' do
        post :create, body: '', format: :json

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with invalid data structure' do
      it 'enqueues job even with invalid structure (validation happens in job)' do
        invalid_data = { 'invalid' => 'structure' }

        expect(RestaurantImportJob).to receive(:perform_later).with(invalid_data).and_return(
          double(job_id: 'job_789')
        )

        post :create, body: invalid_data.to_json, format: :json

        expect(response).to have_http_status(:accepted)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['status']).to eq('queued')
      end
    end
  end

  describe 'POST #upload' do
    context 'with valid file upload' do
      it 'enqueues import job from uploaded file' do
        file = Tempfile.new([ 'test', '.json' ])
        file.write(valid_json_data.to_json)
        file.rewind

        # Now the job receives the file path, not the JSON content
        expect(RestaurantImportJob).to receive(:perform_later) do |file_path|
          # Verify it's a file path string
          expect(file_path).to be_a(String)
          expect(file_path).to include('tmp/imports/import_')
          expect(File.exist?(file_path)).to be true

          double(job_id: 'job_file_123')
        end

        post :upload, params: { file: Rack::Test::UploadedFile.new(file.path, 'application/json') }

        expect(response).to have_http_status(:accepted)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Import job enqueued successfully')
        expect(json_response['job_id']).to eq('job_file_123')

        file.close
        file.unlink
      end
    end

    context 'with missing file' do
      it 'returns bad request when no file provided' do
        post :upload

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('No file provided')
      end
    end

    context 'with invalid file content' do
      it 'returns bad request for file with invalid JSON' do
        file = Tempfile.new([ 'test', '.json' ])
        file.write('invalid json content')
        file.rewind

        post :upload, params: { file: Rack::Test::UploadedFile.new(file.path, 'application/json') }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Invalid JSON format in uploaded file')

        file.close
        file.unlink
      end
    end
  end

  describe 'error handling' do
    it 'handles unexpected errors gracefully' do
      allow(RestaurantImportJob).to receive(:perform_later).and_raise(StandardError, 'Unexpected error')

      post :create, body: valid_json_data.to_json, format: :json

      expect(response).to have_http_status(:internal_server_error)

      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
      expect(json_response['error']).to eq('Failed to enqueue import job')
      expect(json_response['details']).to eq('Unexpected error')
    end
  end
end
