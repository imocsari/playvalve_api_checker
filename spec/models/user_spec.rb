require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) } # Use FactoryBot build here

  it 'is valid with valid attributes' do
    expect(subject).to be_valid
  end

  it 'is not valid without an idfa' do
    subject.idfa = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:idfa]).to include("can't be blank")
  end

  it 'is not valid with invalid UUID format' do
    subject.idfa = 'invalid-uuid'
    expect(subject).not_to be_valid
    expect(subject.errors[:idfa]).to include('must be a valid UUID')
  end

  it 'is not valid with a duplicate idfa (case insensitive)' do
    create(:user, idfa: '8264148c-be95-4b2b-b260-6ee98dd53bf6')
    duplicate_user = build(:user, idfa: '8264148c-BE95-4b2b-B260-6ee98dd53bf6')
    expect(duplicate_user).not_to be_valid
    expect(duplicate_user.errors[:idfa]).to include('has already been taken')
  end

  it 'defaults ban_status to not_banned' do
    user = create(:user, idfa: 'c1d2e3f4-5678-90ab-cdef-1234567890ab')
    expect(user.ban_status).to eq('not_banned')
  end

  it 'encrypts idfa and stores encrypted value' do
    user = create(:user, idfa: '123e4567-e89b-12d3-a456-426614174000')
    raw_value = User.connection.select_value("SELECT idfa FROM users WHERE id = #{user.id}")

    expect(raw_value).to be_present
    expect(raw_value).not_to eq('123e4567-e89b-12d3-a456-426614174000')
  end
end
