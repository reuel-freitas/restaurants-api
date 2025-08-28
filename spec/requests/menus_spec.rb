require 'swagger_helper'

RSpec.describe 'Menus API', type: :request do
  path '/menus' do
    get 'Lista todos os menus' do
      tags 'Menus'
      produces 'application/json'
      description 'Retorna uma lista de todos os menus disponíveis'

      response '200', 'menus encontrados' do
        schema type: :object,
          properties: {
            menus: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string },
                  restaurant_id: { type: :integer },
                  created_at: { type: :string, format: 'date-time' },
                  updated_at: { type: :string, format: 'date-time' }
                }
              }
            }
          }

        let!(:menu1) { create(:menu, name: 'Lunch') }
        let!(:menu2) { create(:menu, name: 'Dinner') }

        run_test!
      end
    end
  end

  path '/menus/{id}' do
    get 'Recupera um menu específico' do
      tags 'Menus'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true,
                description: 'ID do menu'

      response '200', 'menu encontrado' do
        schema type: :object,
          properties: {
            menu: {
              type: :object,
              properties: {
                id: { type: :integer },
                name: { type: :string },
                restaurant_id: { type: :integer },
                created_at: { type: :string, format: 'date-time' },
                updated_at: { type: :string, format: 'date-time' },
                restaurant: {
                  type: :object,
                  properties: {
                    id: { type: :integer },
                    name: { type: :string }
                  }
                },
                menu_items: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: { type: :integer },
                      name: { type: :string },
                      price: { type: :number, format: :float }
                    }
                  }
                }
              }
            }
          }

        let(:menu) { create(:menu, name: 'Lunch') }
        let(:id) { menu.id }

        run_test!
      end

      response '404', 'menu não encontrado' do
        let(:id) { '999' }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end
  end
end
