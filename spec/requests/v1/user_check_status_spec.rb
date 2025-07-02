# spec/requests/v1/user_check_status_spec.rb
require 'rails_helper'

RSpec.describe 'User Check Status API', type: :request do
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }
  let(:idfa) { SecureRandom.uuid }
  let(:ip) { '1.2.3.4' }
  let(:country) { 'US' }
  let(:rooted_device) { false }
  let(:vpn) { false }
  let(:proxy) { false }
  let(:ban_status) { 'not_banned' }

  let(:params) do
    {
      idfa:,
      ip:,
      country:,
      rooted_device:,
      vpn:,
      proxy:,
      ban_status:
    }
  end

  let!(:user) { create(:user, idfa:, ban_status: :not_banned) }

  before do
    # Stub Redis calls for blacklist checks
    allow($redis).to receive(:sismember).with('manual_banned_ips', ip).and_return(false)
    allow($redis).to receive(:sismember).with('country_blacklist', country).and_return(false)

    # Catch-all stub to prevent unexpected Redis calls causing errors
    allow($redis).to receive(:sismember).and_return(false)

    # Stub VPN service (if used in your service)
    allow_any_instance_of(VpnCheckService).to receive(:banned?).and_return(false)
  end

  describe 'POST /v1/user/check_status' do
    context 'with valid params' do
      it 'creates a new user if none exists' do
        user.destroy! # ensure no user exists

        expect do
          post '/v1/user/check_status', params: params.to_json, headers:
        end.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['ban_status']).to eq('not_banned')
      end

      it 'does not create a new user if one exists, just updates' do
        # user is created by let!(:user) above

        expect do
          post '/v1/user/check_status', params: params.to_json, headers:
        end.not_to change(User, :count)

        expect(user.reload.ban_status).to eq('not_banned')
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with rooted device or blacklisted IP' do
      before do
        allow($redis).to receive(:sismember).with('manual_banned_ips', ip).and_return(true) # simulate IP blacklisted
      end

      it 'returns banned status' do
        post('/v1/user/check_status', params: params.to_json, headers:)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['ban_status']).to eq('banned')
      end

      it 'updates the user ban_status to banned' do
        post('/v1/user/check_status', params: params.to_json, headers:)

        expect(user.reload.ban_status).to eq('banned')
      end
    end

    context 'with invalid params' do
      let(:params) { { idfa: nil } } # Missing required fields

      it 'returns an error message' do
        post('/v1/user/check_status', params: params.to_json, headers:)

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end
  end
end
