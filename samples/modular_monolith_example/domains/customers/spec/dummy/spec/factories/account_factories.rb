FactoryBot.define do
  factory :account, class: Customers::Account do
    email 'test@test.com'
    password 'test1234'
    password_confirmation 'test1234'
  end
end

# REQUIRE
# profile_id
