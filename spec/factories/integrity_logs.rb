FactoryBot.define do
  factory :integrity_log do
    idfa { "MyString" }
    ban_status { 1 }
    ip { "MyString" }
    rooted_device { false }
    country { "MyString" }
    proxy { false }
    vpn { false }
  end
end
