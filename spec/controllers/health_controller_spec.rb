require 'rails_helper'

RSpec.describe HealthController, type: :controller do
  describe 'GET #show' do
    before do
      get :show
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'returns HTML response with health check content' do
      expect(response.content_type).to include('text/html')
      expect(response.body).to include('<!DOCTYPE html>')
      expect(response.body).to include('Restaurants API')
      expect(response.body).to include('Health Check')
    end

    it 'includes health status information' do
      expect(response.body).to include('Status:')
      expect(response.body).to include('Database')
      expect(response.body).to include('Background Jobs')
      expect(response.body).to include('Ruby Version:')
      expect(response.body).to include('Rails Version:')
    end

    it 'includes restaurant statistics' do
      expect(response.body).to include('Restaurant Statistics')
      expect(response.body).to include('Restaurants')
      expect(response.body).to include('Menus')
      expect(response.body).to include('Menu Items')
    end

    context 'when requesting JSON format' do
      before do
        get :show, format: :json
      end

      it 'returns JSON response' do
        expect(response.content_type).to include('application/json')
      end

      it 'returns valid JSON structure' do
        json_response = JSON.parse(response.body)
        expect(json_response).to include('application', 'version', 'environment')
        expect(json_response).to include('restaurant_stats')
      end

      it 'includes restaurant statistics in JSON' do
        json_response = JSON.parse(response.body)
        expect(json_response['restaurant_stats']).to include('summary', 'restaurants', 'pricing_analysis')

        summary = json_response['restaurant_stats']['summary']
        expect(summary).to include('total_restaurants', 'total_menus', 'total_menu_items')
      end
    end

    context 'when requesting text format' do
      before do
        get :show, format: :text
      end

      it 'returns text response' do
        expect(response.content_type).to include('text/plain')
      end

      it 'includes status information in text' do
        expect(response.body).to include('Restaurants API Health Check')
        expect(response.body).to include('Status:')
        expect(response.body).to include('Restaurant Statistics')
      end

      it 'includes restaurant summary in text' do
        expect(response.body).to include('Total Restaurants:')
        expect(response.body).to include('Total Menus:')
        expect(response.body).to include('Total Menu Items:')
      end
    end

    context 'when requesting HTML format' do
      before do
        get :show
      end

      it 'returns HTML response' do
        expect(response.content_type).to include('text/html')
      end

      it 'includes HTML content' do
        expect(response.body).to include('<!DOCTYPE html>')
        expect(response.body).to include('Restaurants API')
        expect(response.body).to include('Health Check')
        expect(response.body).to include('Restaurant Statistics')
      end

      it 'includes restaurant summary section' do
        expect(response.body).to include('Restaurant Summary')
        expect(response.body).to include('Total Restaurants')
        expect(response.body).to include('Sample Shown')
      end
    end
  end

  describe 'service integration' do
    it 'calls HealthCheckService' do
      expect(HealthCheckService).to receive(:perform_health_check).and_return({
        status: {
          application: 'Restaurants API',
          version: '1.0.0',
          environment: 'test',
          timestamp: DateTime.parse('2024-01-01'),
          uptime: '1 day',
          database: { status: 'healthy', message: 'OK' },
          background_jobs: { status: 'healthy', message: 'OK' },
          system_info: { ruby_version: '3.2.2', rails_version: '8.0.2' }
        },
        overall_status: 'healthy'
      })

      get :show
    end

    it 'calls RestaurantStatsService' do
      expect(RestaurantStatsService).to receive(:generate_stats).with(
        with_items: false
      ).and_return({
        summary: {
          total_restaurants: 50,
          total_menus: 145,
          total_menu_items: 44
        },
        restaurants: {
          total_count: 50,
          sample_restaurants: [
            { id: 1, name: 'Restaurant 1', menu_count: 3, total_items: 12 }
          ],
          message: 'Showing 1 of 50 restaurants'
        },
        pricing_analysis: {
          price_ranges: { min: 2.91, max: 75.86, average: 22.13 }
        }
      })

      get :show
    end
  end
end
