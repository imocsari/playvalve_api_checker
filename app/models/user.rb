class User < ApplicationRecord
  include UuidValidatable

  encrypts :idfa, deterministic: true, downcase: true

  enum ban_status: {
    banned: 0,
    not_banned: 1
  }, _prefix: :ban_status

  validates :idfa, presence: true, uniqueness: { case_sensitive: false }
  validates :ban_status, presence: true

  # Finds or creates a user and updates the ban_status if needed
  def self.find_or_create_and_update(idfa, ban_status)
    user = find_or_initialize_by(idfa:)
    user.ban_status = ban_status if user.new_record? || user.ban_status != ban_status.to_s
    user.save!
    user
  end
end
