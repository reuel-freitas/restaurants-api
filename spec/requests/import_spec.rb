require 'swagger_helper'

RSpec.describe 'Import API', type: :request do
  path '/import' do
    post 'Envia dados JSON para importação' do
      tags 'Import'
      consumes 'application/json'
      produces 'application/json'
      description 'Envia dados JSON para importação de restaurantes, menus e itens de menu'

      parameter name: :import_data, in: :body, schema: {
        type: :object,
        properties: {
          restaurants: {
            type: :array,
            items: {
              type: :object,
              properties: {
                name: { type: :string },
                menus: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      name: { type: :string },
                      menu_items: {
                        type: :array,
                        items: {
                          type: :object,
                          properties: {
                            name: { type: :string },
                            price: { type: :number, format: :float }
                          },
                          required: [ 'name', 'price' ]
                        }
                      }
                    },
                    required: [ 'name', 'menu_items' ]
                  }
                }
              },
              required: [ 'name', 'menus' ]
            }
          }
        },
        required: [ 'restaurants' ]
      }

      response '202', 'Import job enqueued successfully' do
        let(:import_data) do
          {
            restaurants: [
              {
                name: "Poppo's Cafe",
                menus: [
                  {
                    name: 'lunch',
                    menu_items: [
                      { name: 'Burger', price: 9.00 },
                      { name: 'Small Salad', price: 5.00 }
                    ]
                  }
                ]
              }
            ]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['success']).to be true
          expect(data['message']).to eq('Import job enqueued successfully')
          expect(data['job_id']).to be_present
          expect(data['status']).to eq('queued')
        end
      end

      response '400', 'Invalid data structure' do
        let(:import_data) { '{ "unclosed": "quote }' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['success']).to be false
          expect(data['error']).to eq('Invalid data structure')
        end
      end

      response '400', 'Invalid data structure' do
        let(:import_data) { '["not", "an", "object"]' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['success']).to be false
          expect(data['error']).to eq('Invalid data structure')
        end
      end

      response '202', 'Import job enqueued even with invalid structure' do
        let(:import_data) { { invalid: 'structure' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['success']).to be true
          expect(data['message']).to eq('Import job enqueued successfully')
          expect(data['job_id']).to be_present
          expect(data['status']).to eq('queued')
        end
      end
    end
  end

  path '/import/status/{job_id}' do
    get 'Verifica o status de um job de importação' do
      tags 'Import'
      produces 'application/json'
      description 'Verifica o status atual de um job de importação pelo ID'

      parameter name: :job_id, in: :path, type: :string, required: true,
                description: 'ID do job de importação'

      response '200', 'Job status retrieved successfully' do
        let(:job_id) { 'valid_job_id' }

        before do
          allow(SolidQueue::Job).to receive(:find_by).with(active_job_id: 'valid_job_id')
            .and_return(double(
              active_job_id: 'valid_job_id',
              finished_at: nil,
              failed_at: nil,
              status: 'pending'
            ))
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['success']).to be true
          expect(data['job_id']).to eq('valid_job_id')
          expect(data['status']['state']).to eq('queued')
        end
      end

      response '404', 'Job not found' do
        let(:job_id) { 'invalid_job_id' }

        before do
          allow(SolidQueue::Job).to receive(:find_by).with(active_job_id: 'invalid_job_id')
            .and_return(nil)
          allow(SolidQueue::Job).to receive(:find_by).with(id: 'invalid_job_id')
            .and_return(nil)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['success']).to be false
          expect(data['error']).to eq('Job not found')
        end
      end
    end
  end
end
