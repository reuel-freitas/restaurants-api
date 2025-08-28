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
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      response '202', 'job de importação enfileirado com sucesso' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            job_id: { type: :string },
            status: { type: :string },
            check_status_command: { type: :string }
          }

        let(:import_data) do
          {
            restaurants: [
              {
                name: "Restaurante Teste",
                menus: [
                  {
                    name: "Menu Teste",
                    menu_items: [
                      { name: "Item Teste", price: 10.50 }
                    ]
                  }
                ]
              }
            ]
          }
        end

        run_test!
      end

      response '400', 'formato JSON inválido' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            error: { type: :string },
            details: { type: :string }
          }

        let(:import_data) { 'invalid json' }
        run_test!
      end

      response '500', 'erro interno do servidor' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            error: { type: :string },
            details: { type: :string }
          }

        # Simular erro interno
        before do
          allow(RestaurantImportJob).to receive(:perform_later).and_raise(StandardError, "Erro interno")
        end

        let(:import_data) do
          {
            restaurants: [
              { name: "Restaurante Teste" }
            ]
          }
        end

        run_test!
      end
    end
  end

  path '/import/upload' do
    post 'Faz upload de arquivo JSON para importação' do
      tags 'Import'
      consumes 'multipart/form-data'
      produces 'application/json'
      description 'Faz upload de um arquivo JSON para importação de restaurantes, menus e itens de menu'

      parameter name: :file, in: :formData, type: :file, required: true,
                description: 'Arquivo JSON para importação'

      response '202', 'job de importação enfileirado com sucesso' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            job_id: { type: :string },
            status: { type: :string },
            check_status_command: { type: :string }
          }

        let(:file) { fixture_file_upload('restaurant_data.json', 'application/json') }

        run_test!
      end

      response '400', 'arquivo não fornecido' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            error: { type: :string }
          }

        let(:file) { nil }
        run_test!
      end

      response '400', 'formato JSON inválido no arquivo' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            error: { type: :string },
            details: { type: :string }
          }

        let(:file) { fixture_file_upload('invalid_data.txt', 'text/plain') }
        run_test!
      end
    end
  end

  path '/import/status/{job_id}' do
    get 'Verifica o status de um job de importação' do
      tags 'Import'
      produces 'application/json'
      parameter name: :job_id, in: :path, type: :string, required: true,
                description: 'ID do job de importação'

      response '200', 'status do job encontrado' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            job_id: { type: :string },
            status: {
              type: :object,
              properties: {
                state: { type: :string },
                message: { type: :string },
                results: { type: :object, nullable: true }
              }
            }
          }

        let(:job_id) { 'valid-job-id' }

        before do
          allow(SolidQueue::Job).to receive(:find_by).and_return(
            double('job', status: 'finished')
          )
          allow_any_instance_of(ImportController).to receive(:get_cached_results).and_return(
            { restaurants_created: 5, menus_created: 10, menu_items_created: 25 }
          )
        end

        run_test!
      end

      response '400', 'ID do job não fornecido' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            error: { type: :string }
          }

        let(:job_id) { '' }
        run_test!
      end

      response '404', 'job não encontrado' do
        schema type: :object,
          properties: {
            success: { type: :boolean },
            error: { type: :string }
          }

        let(:job_id) { 'non-existent-job' }

        before do
          allow(SolidQueue::Job).to receive(:find_by).and_return(nil)
        end

        run_test!
      end
    end
  end
end
