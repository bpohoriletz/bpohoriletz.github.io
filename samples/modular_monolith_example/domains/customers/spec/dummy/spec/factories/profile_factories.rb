FactoryBot.define do
  factory :profile, class: Customers::Profile do
    first_name 'test'
    last_name 'test'
  end

  factory :admin_profile, parent: :profile do
    permissin_level 100
  end
end

# REQUIRE
# account_id
