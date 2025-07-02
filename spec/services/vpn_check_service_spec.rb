# spec/services/vpn_check_service_spec.rb
require 'rails_helper'

RSpec.describe VpnCheckService do
  let(:ip) { '1.2.3.4' }
  let(:cache_key) { "vpnapi:#{ip}" }
  let(:default_result) { { vpn: false, proxy: false, tor: false } }
  let(:cached_json) { { vpn: true, proxy: false, tor: false }.to_json }
  let(:redis_double) { instance_double('Redis') }

  let(:api_response_body) do
    {
      'security' => {
        'vpn' => true,
        'proxy' => false,
        'tor' => false
      }
    }.to_json
  end

  before do
    # Stub $redis globally without reassigning/removing
    allow($redis).to receive(:get).and_call_original # or stub default behavior if needed
  end

  describe '.lookup' do
    context 'when IP is blank' do
      it 'returns default result' do
        expect(described_class.lookup('')).to eq(default_result)
        expect(described_class.lookup(nil)).to eq(default_result)
      end
    end

    context 'when cache hit' do
      it 'returns cached parsed result' do
        allow($redis).to receive(:get).with(cache_key).and_return(cached_json)
        expect(described_class.lookup(ip)).to eq(JSON.parse(cached_json, symbolize_names: true))
      end

      it 'returns default result and fetches API if cached JSON is invalid' do
        allow($redis).to receive(:get).with(cache_key).and_return('invalid json')
        allow(described_class).to receive(:fetch_from_api).with(ip).and_return(default_result)
        expect(described_class.lookup(ip)).to eq(default_result)
      end
    end

    context 'when cache miss' do
      before do
        allow($redis).to receive(:get).with(cache_key).and_return(nil)
      end

      it 'calls VPN API and caches the result' do
        fake_response = instance_double('Faraday::Response', status: 200, body: api_response_body)
        expect(Faraday).to receive(:get).and_return(fake_response)
        expect($redis).to receive(:setex).with(cache_key, kind_of(Integer), kind_of(String))

        result = described_class.lookup(ip)
        expect(result).to eq(vpn: true, proxy: false, tor: false)
      end

      it 'returns default result on non-200 response' do
        fake_response = instance_double('Faraday::Response', status: 500, body: '')
        allow(Faraday).to receive(:get).and_return(fake_response)
        expect($redis).not_to receive(:setex)

        result = described_class.lookup(ip)
        expect(result).to eq(default_result)
      end

      it 'returns default result on JSON parse error' do
        fake_response = instance_double('Faraday::Response', status: 200, body: 'invalid json')
        allow(Faraday).to receive(:get).and_return(fake_response)
        expect($redis).not_to receive(:setex)

        result = described_class.lookup(ip)
        expect(result).to eq(default_result)
      end

      it 'returns default result on network error' do
        allow(Faraday).to receive(:get).and_raise(StandardError.new('network down'))
        expect($redis).not_to receive(:setex)

        result = described_class.lookup(ip)
        expect(result).to eq(default_result)
      end
    end
  end

  describe '#banned?' do
    it 'returns true if VPN detected' do
      allow(described_class).to receive(:lookup).with(ip).and_return(vpn: true, proxy: false, tor: false)
      expect(described_class.new(ip).banned?).to be true
    end

    it 'returns true if proxy detected' do
      allow(described_class).to receive(:lookup).with(ip).and_return(vpn: false, proxy: true, tor: false)
      expect(described_class.new(ip).banned?).to be true
    end

    it 'returns true if tor detected' do
      allow(described_class).to receive(:lookup).with(ip).and_return(vpn: false, proxy: false, tor: true)
      expect(described_class.new(ip).banned?).to be true
    end

    it 'returns false if none detected' do
      allow(described_class).to receive(:lookup).with(ip).and_return(vpn: false, proxy: false, tor: false)
      expect(described_class.new(ip).banned?).to be false
    end
  end
end
