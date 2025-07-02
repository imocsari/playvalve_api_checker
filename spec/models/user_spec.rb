require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:idfa) }
    it { is_expected.to validate_uniqueness_of(:idfa).case_insensitive }

    # Manual test for ban_status presence because of before_validation default
    it 'is invalid without a ban_status' do
      user = build(:user)
      user.ban_status = nil
      user.validate
      expect(user.errors[:ban_status]).to include("can't be blank")
    end
  end

  describe 'callbacks' do
    it 'sets default ban_status to not_banned on create' do
      user = User.new(idfa: SecureRandom.uuid)
      user.validate
      expect(user.ban_status).to eq('not_banned')
    end
  end

  describe '.find_or_create_and_update' do
    let(:idfa) { SecureRandom.uuid }

    it 'creates a new user with given ban_status' do
      user = User.find_or_create_and_update(idfa, :banned)
      expect(user).to be_persisted
      expect(user.idfa).to eq(idfa)
      expect(user.ban_status).to eq('banned')
    end

    it 'updates ban_status if different' do
      user = create(:user, idfa:, ban_status: :not_banned)
      updated_user = User.find_or_create_and_update(idfa, :banned)
      expect(updated_user.id).to eq(user.id)
      expect(updated_user.ban_status).to eq('banned')
    end

    it 'does not update ban_status if the same' do
      user = create(:user, idfa:, ban_status: :banned)
      expect(user).not_to receive(:save!)
      User.find_or_create_and_update(idfa, :banned)
    end
  end
end
