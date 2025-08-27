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
      it 'imports data successfully' do
        post :create, body: valid_json_data.to_json, format: :json

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['restaurants_processed']).to eq(1)
        expect(json_response['data']['menus_processed']).to eq(1)
        expect(json_response['data']['items_processed']).to eq(2)
      end

      it 'returns detailed logs' do
        post :create, body: valid_json_data.to_json, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['logs']).to be_present
        expect(json_response['logs'].length).to be > 0

        log_types = json_response['logs'].map { |log| log['entity_type'] }
        expect(log_types).to include('restaurant', 'menu', 'menu_item')
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
      it 'returns unprocessable entity for invalid structure' do
        invalid_data = { 'invalid' => 'structure' }
        post :create, body: invalid_data.to_json, format: :json

        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors']).to be_present
      end
    end
  end

  describe 'POST #upload' do
    context 'with valid file upload' do
      it 'imports data from uploaded file' do
        file = Tempfile.new([ 'test', '.json' ])
        file.write(valid_json_data.to_json)
        file.rewind

        post :upload, params: { file: Rack::Test::UploadedFile.new(file.path, 'application/json') }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['restaurants_processed']).to eq(1)

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
      allow_any_instance_of(RestaurantImportService).to receive(:import).and_raise(StandardError, 'Unexpected error')

      post :create, body: valid_json_data.to_json, format: :json

      expect(response).to have_http_status(:internal_server_error)

      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
      expect(json_response['error']).to eq('Import failed')
      expect(json_response['details']).to eq('Unexpected error')
    end
  end
end
