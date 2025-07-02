FactoryBot.define do
  factory :integrity_log do
    idfa { SecureRandom.uuid }
    ip { '192.168.1.1' }
    country { 'US' }
    rooted_device { false }
    vpn { false }
    proxy { false }
    ban_status { :not_banned }
  end
end
