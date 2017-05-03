require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit users_url

    assert_selector "h1", text: "User"
  end

  test 'creating new user' do
    visit users_url
    click_on 'New User'
    fill_in 'First name', with: 'Bohdan'
    fill_in 'Last name', with: 'Pohorilets'
    click_on 'Create User'
    visit users_url
    assert_text 'Bohdan Pohorilets'
  end

  test 'editing existing user' do
    User.new(first_name: 'Bohdan', last_name: 'Pohorilets').save
    visit edit_user_url(User.first)
    fill_in 'First name', with: 'First'
    fill_in 'Last name', with: 'Last'
    click_on 'Update User'
    assert_text 'First Last'
  end
end
