# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Restaurants API',
        version: 'v1',
        description: 'API para gerenciamento de restaurantes, menus e itens de menu',
        contact: {
          name: 'API Support',
          email: 'support@restaurants-api.com'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'api.restaurants.com',
              description: 'Production API server'
            }
          }
        }
      ],
      components: {
        schemas: {
          error: {
            type: 'object',
            properties: {
              error: { type: 'string' },
              message: { type: 'string' }
            }
          },
          restaurant: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string' },
              created_at: { type: 'string', format: 'date-time' },
              updated_at: { type: 'string', format: 'date-time' }
            },
            required: [ 'id', 'name' ]
          },
          menu: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string' },
              restaurant_id: { type: 'integer' },
              created_at: { type: 'string', format: 'date-time' },
              updated_at: { type: 'string', format: 'date-time' }
            },
            required: [ 'id', 'name', 'restaurant_id' ]
          },
          menu_item: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string' },
              created_at: { type: 'string', format: 'date-time' },
              updated_at: { type: 'string', format: 'date-time' }
            },
            required: [ 'id', 'name' ]
          },
          menu_menu_item: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string' },
              price: { type: 'number', format: 'float' }
            },
            required: [ 'id', 'name', 'price' ]
          },
          import_request: {
            type: 'object',
            properties: {
              restaurants: {
                type: 'array',
                items: {
                  '$ref' => '#/components/schemas/restaurant_import'
                }
              }
            },
            required: [ 'restaurants' ]
          },
          restaurant_import: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              menus: {
                type: 'array',
                items: {
                  '$ref' => '#/components/schemas/menu_import'
                }
              }
            },
            required: [ 'name' ]
          },
          menu_import: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              menu_items: {
                type: 'array',
                items: {
                  '$ref' => '#/components/schemas/menu_item_import'
                }
              }
            },
            required: [ 'name' ]
          },
          menu_item_import: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              price: { type: 'number', format: 'float' }
            },
            required: [ 'name', 'price' ]
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
