require 'rails_helper'
require 'securerandom'

RSpec.describe CheckStatusService do
  let(:idfa) { SecureRandom.uuid }
  let(:ip) { '1.2.3.4' }
  let(:country) { 'US' }
  let(:rooted_device) { false }

  subject(:service) { described_class.new(idfa:, ip:, country:, rooted_device:) }

  before do
    # Stub Redis calls by default
    allow($redis).to receive(:sismember).and_return(false)

    # Stub IntegrityLoggerService (assuming it exists and has a .log method)
    allow(IntegrityLoggerService).to receive(:log)
  end

  describe 'validations' do
    it 'is invalid without idfa' do
      service = described_class.new(idfa: nil, ip:, country:, rooted_device:)
      expect(service.valid?).to be_falsey
      expect(service.call[:error]).to match(/Idfa can't be blank/i)
    end

    it 'is invalid without ip' do
      service = described_class.new(idfa:, ip: nil, country:, rooted_device:)
      expect(service.valid?).to be_falsey
      expect(service.call[:error]).to match(/Ip can't be blank/i)
    end

    it 'is invalid without country' do
      service = described_class.new(idfa:, ip:, country: nil, rooted_device:)
      expect(service.valid?).to be_falsey
      expect(service.call[:error]).to match(/Country can't be blank/i)
    end
  end

  describe '#call' do
    let!(:user) { User.create!(idfa:, ban_status: User.ban_statuses[:not_banned]) }

    context 'when user is banned' do
      before do
        user.update!(ban_status: User.ban_statuses[:banned])
      end

      it 'returns banned status without further checks' do
        expect(service.call).to eq(ban_status: 'banned')
        expect(IntegrityLoggerService).to have_received(:log).with(
          idfa:,
          ip:,
          country:,
          rooted_device: false,
          vpn: anything,
          proxy: false,
          ban_status: 'banned'
        )
      end
    end

    context 'when user is not banned' do
      before do
        allow_any_instance_of(VpnCheckService).to receive(:banned?).and_return(false)
      end

      it 'returns not_banned if no banned conditions' do
        expect(service.call).to eq(ban_status: 'not_banned')
      end

      it 'updates user ban_status if conditions change' do
        # Make rooted_device true to trigger banned condition
        service_with_rooted = described_class.new(idfa:, ip:, country:, rooted_device: true)

        expect(service_with_rooted.call).to eq(ban_status: 'banned')

        expect(User.find_by(idfa:).ban_status).to eq('banned')
      end
    end

    context 'when redis blacklists are triggered' do
      before do
        allow($redis).to receive(:sismember).with('country_blacklist', country).and_return(true)
      end

      it 'detects country blacklist and bans user' do
        expect(service.call).to eq(ban_status: 'banned')
      end
    end

    context 'when manual IP blacklist is triggered' do
      before do
        allow($redis).to receive(:sismember).with('manual_banned_ips', ip).and_return(true)
      end

      it 'detects manual IP blacklist and bans user' do
        expect(service.call).to eq(ban_status: 'banned')
      end
    end

    context 'when user save fails' do
      it 'returns error response if save fails' do
        user = User.new
        allow(User).to receive(:find_or_initialize_by).and_return(user)
        allow(user).to receive(:ban_status=).and_call_original
        allow(user).to receive(:save).and_return(false)
        allow(user).to receive_message_chain(:errors, :full_messages).and_return(['some error'])

        expect(service.call).to eq(error: 'some error')
      end
    end
  end
end
