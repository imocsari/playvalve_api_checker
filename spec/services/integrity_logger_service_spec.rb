require 'rails_helper'

RSpec.describe IntegrityLoggerService do
  let(:valid_params) do
    {
      idfa: SecureRandom.uuid,
      ip: '1.2.3.4',
      country: 'US',
      rooted_device: false,
      vpn: true,
      proxy: false,
      ban_status: 'banned'
    }
  end

  describe '#initialize' do
    it 'raises ArgumentError if destination is not :database' do
      expect do
        described_class.new(destination: :file)
      end.to raise_error(ArgumentError, /Only :database supported so far/)
    end

    it 'accepts :database as destination' do
      service = described_class.new(destination: :database)
      expect(service).to be_a(described_class)
    end
  end

  describe '#log (instance method)' do
    subject(:service) { described_class.new(destination: :database) }

    it 'calls log_to_database with given params' do
      expect(IntegrityLog).to receive(:create!).with(
        hash_including(
          idfa: valid_params[:idfa],
          ip: valid_params[:ip],
          country: valid_params[:country],
          rooted_device: valid_params[:rooted_device],
          vpn: valid_params[:vpn],
          proxy: valid_params[:proxy],
          ban_status: IntegrityLog.ban_statuses[valid_params[:ban_status]]
        )
      )

      service.log(**valid_params)
    end

    it 'raises error for unsupported destination' do
      service = described_class.new(destination: :database)
      # Manually set @destination to unsupported value for test
      service.instance_variable_set(:@destination, :file)

      expect do
        service.log(**valid_params)
      end.to raise_error(RuntimeError, /Unsupported destination: file/)
    end
  end

  describe '.log (class method)' do
    it 'creates IntegrityLog record with correct attributes' do
      expect do
        described_class.log(**valid_params)
      end.to change(IntegrityLog, :count).by(1)

      last_log = IntegrityLog.last
      expect(last_log.idfa).to eq(valid_params[:idfa])
      expect(last_log.ip).to eq(valid_params[:ip])
      expect(last_log.country).to eq(valid_params[:country])
      expect(last_log.rooted_device).to eq(valid_params[:rooted_device])
      expect(last_log.vpn).to eq(valid_params[:vpn])
      expect(last_log.proxy).to eq(valid_params[:proxy])
      expect(last_log.ban_status).to eq(valid_params[:ban_status])
    end
  end
end
