require 'rails_helper'

RSpec.describe 'V1::User', type: :request do
  describe 'POST /v1/user/check_status' do
    it 'returns not_banned by default' do
      post '/v1/user/check_status',
           headers: { 'CONTENT_TYPE' => 'application/json', 'CF-IPCountry' => 'US' },
           params: { idfa: 'test-idfa', rooted_device: false }.to_json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ 'ban_status' => 'not_banned' })
    end
  end
end
