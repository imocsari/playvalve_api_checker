class IntegrityLog < ApplicationRecord
  enum ban_status: {
    not_banned: 1,
    banned: 0
  }, _prefix: :ban_status
end
