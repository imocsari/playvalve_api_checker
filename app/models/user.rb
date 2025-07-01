class User < ApplicationRecord
  encrypts :idfa, deterministic: true, downcase: true

  enum ban_status: { not_banned: 0, banned: 1 }

  validates :idfa, presence: true, uniqueness: true,
                   format: { with: /\A[0-9a-fA-F-]{36}\z/, message: 'must be a valid UUID' }
  validates :ban_status, presence: true
end
