require 'swagger_helper'

RSpec.describe 'Restaurants API', type: :request do
  path '/restaurants' do
    get 'Lista todos os restaurantes' do
      tags 'Restaurants'
      produces 'application/json'
      description 'Retorna uma lista de todos os restaurantes disponíveis'

      response '200', 'restaurantes encontrados' do
        schema type: :object,
          properties: {
            restaurants: {
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

        let!(:restaurant1) { create(:restaurant, name: "Poppo's Cafe") }
        let!(:restaurant2) { create(:restaurant, name: "Casa del Poppo") }

        run_test!
      end
    end
  end

  path '/restaurants/{id}' do
    get 'Recupera um restaurante específico' do
      tags 'Restaurants'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true,
                description: 'ID do restaurante'

      response '200', 'restaurante encontrado' do
        schema type: :object,
          properties: {
            restaurant: {
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
                      name: { type: :string },
                      restaurant_id: { type: :integer },
                      created_at: { type: :string, format: 'date-time' },
                      updated_at: { type: :string, format: 'date-time' },
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
              }
            }
          }

        let(:restaurant) { create(:restaurant, name: "Poppo's Cafe") }
        let!(:menu) { create(:menu, restaurant: restaurant, name: 'Lunch') }
        let(:id) { restaurant.id }

        run_test!
      end

      response '404', 'restaurante não encontrado' do
        let(:id) { '999' }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end
  end

  path '/restaurants/{restaurant_id}/menus' do
    get 'Lista todos os menus de um restaurante específico' do
      tags 'Restaurants'
      produces 'application/json'
      parameter name: :restaurant_id, in: :path, type: :integer, required: true,
                description: 'ID do restaurante'

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

        let(:restaurant) { create(:restaurant, name: "Poppo's Cafe") }
        let!(:menu1) { create(:menu, restaurant: restaurant, name: 'Lunch') }
        let!(:menu2) { create(:menu, restaurant: restaurant, name: 'Dinner') }
        let(:restaurant_id) { restaurant.id }

        run_test!
      end
    end
  end

  path '/restaurants/{restaurant_id}/menu_items' do
    get 'Lista todos os itens de menu de um restaurante específico' do
      tags 'Restaurants'
      produces 'application/json'
      parameter name: :restaurant_id, in: :path, type: :integer, required: true,
                description: 'ID do restaurante'

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

        let(:restaurant) { create(:restaurant, name: "Poppo's Cafe") }
        let!(:menu) { create(:menu, restaurant: restaurant, name: 'Lunch') }
        let!(:menu_item1) { create(:menu_item, name: 'Burger') }
        let!(:menu_item2) { create(:menu_item, name: 'Salad') }
        let(:restaurant_id) { restaurant.id }

        before do
          MenuMenuItem.create!(menu: menu, menu_item: menu_item1, price: 9.00)
          MenuMenuItem.create!(menu: menu, menu_item: menu_item2, price: 5.00)
        end

        run_test!
      end
    end
  end
end
