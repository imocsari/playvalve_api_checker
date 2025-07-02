class User < ApplicationRecord
  encrypts :idfa, deterministic: true, downcase: true

  enum ban_status: {
    not_banned: 1,
    banned: 0
  }, _prefix: :ban_status

  validates :idfa, presence: true, uniqueness: true
  validates :ban_status, presence: true

  def self.find_or_create_and_update_user(idfa, ban_status)
    user = find_or_initialize_by(idfa:)
    user.ban_status = ban_status
    user.save!
    user
  end
end
