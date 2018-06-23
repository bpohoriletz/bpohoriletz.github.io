# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Customers::Account.create!(
  email: 'test@test.com',
  password: 'Test1234',
  password_confirmation: 'Test1234',
  profile: Customers::Profile.new(
    first_name: 'Test',
    last_name: 'Account',
    google_login: 'test@test.com',
    permissin_level: 100
  )
)
