require 'rails_helper'

RSpec.describe IntegrityLog, type: :model do
  subject { build(:integrity_log) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:idfa) }
    it { is_expected.to validate_presence_of(:ip) }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_presence_of(:ban_status) }
    it { is_expected.to define_enum_for(:ban_status).with_values(banned: 0, not_banned: 1).with_prefix(:ban_status) }
  end

  describe 'UUID validation' do
    it 'is invalid with malformed idfa' do
      subject.idfa = 'invalid-uuid'
      expect(subject).not_to be_valid
      expect(subject.errors[:idfa]).to include('must be a valid UUID')
    end

    it 'is valid with correct UUID format' do
      subject.idfa = SecureRandom.uuid
      expect(subject).to be_valid
    end
  end

  describe 'boolean attributes' do
    it 'is invalid without rooted_device' do
      subject.rooted_device = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:rooted_device]).to include('is not included in the list')
    end

    it 'is invalid without vpn' do
      subject.vpn = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:vpn]).to include('is not included in the list')
    end

    it 'is invalid without proxy' do
      subject.proxy = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:proxy]).to include('is not included in the list')
    end
  end
end
