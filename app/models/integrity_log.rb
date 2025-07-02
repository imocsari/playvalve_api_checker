class IntegrityLog < ApplicationRecord
  self.table_name = 'integrity_logs'

  include UuidValidatable
  # Encrypts the idfa field using deterministic encryption, allowing for case-insensitive queries
  # This is useful for logging and querying integrity checks without exposing raw IDFA values
  encrypts :idfa, deterministic: true, downcase: true

  validates :idfa, presence: true
  validates :ip, presence: true
  validates :country, presence: true
  validates :rooted_device, inclusion: { in: [true, false] }
  validates :vpn, inclusion: { in: [true, false] }
  validates :proxy, inclusion: { in: [true, false] }
  validates :ban_status, presence: true

  enum ban_status: {
    not_banned: 1,
    banned: 0
  }, _prefix: :ban_status
end
