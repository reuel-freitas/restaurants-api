require 'rails_helper'

RSpec.describe 'Menus API', type: :request do
  describe 'GET /menus' do
    let!(:menu1) { create(:menu, name: 'Lunch') }
    let!(:menu2) { create(:menu, name: 'Dinner') }

    it 'returns all menus' do
      get '/menus'

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('menus')
      expect(json_response['menus'].length).to eq(2)

      menu_names = json_response['menus'].map { |m| m['name'] }
      expect(menu_names).to include('Lunch', 'Dinner')
    end
  end

  describe 'GET /menus/:id' do
    let(:menu) { create(:menu, name: 'Lunch') }

    it 'returns the specific menu' do
      get "/menus/#{menu.id}"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('menu')
      expect(json_response['menu']['id']).to eq(menu.id)
      expect(json_response['menu']['name']).to eq('Lunch')
    end

    it 'returns 404 for non-existent menu' do
      get '/menus/999'

      expect(response).to have_http_status(:not_found)
    end
  end
end
