require 'swagger_helper'

RSpec.describe 'Menu Items API', type: :request do
  path '/menu_items' do
    get 'Lista todos os itens de menu' do
      tags 'Menu Items'
      produces 'application/json'
      description 'Retorna uma lista de todos os itens de menu disponíveis'

      response '200', 'itens de menu encontrados' do
        schema type: :object,
          properties: {
            menu_items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string },
                  created_at: { type: :string, format: 'date-time' },
                  updated_at: { type: :string, format: 'date-time' }
                }
              }
            }
          }

        let!(:menu_item1) { create(:menu_item, name: 'Burger') }
        let!(:menu_item2) { create(:menu_item, name: 'Salad') }

        run_test!
      end
    end
  end

  path '/menu_items/{id}' do
    get 'Recupera um item de menu específico' do
      tags 'Menu Items'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true,
                description: 'ID do item de menu'

      response '200', 'item de menu encontrado' do
        schema type: :object,
          properties: {
            menu_item: {
              type: :object,
              properties: {
                id: { type: :integer },
                name: { type: :string },
                created_at: { type: :string, format: 'date-time' },
                updated_at: { type: :string, format: 'date-time' },
                menus: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: { type: :integer },
                      name: { type: :string }
                    }
                  }
                }
              }
            }
          }

        let(:menu_item) { create(:menu_item, name: 'Burger') }
        let(:id) { menu_item.id }

        run_test!
      end

      response '404', 'item de menu não encontrado' do
        let(:id) { '999' }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end
  end
end
