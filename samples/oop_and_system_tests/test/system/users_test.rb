require 'application_system_test_case'
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'show')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'new')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'index')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'edit')

class UsersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit users_url

    assert_selector "h1", text: "User"
  end

  test 'creating new user' do
    ::Pages::Users::Index.new.instance_eval do
      visit
      new_user_link.click
    end

    ::Pages::Users::New.new.instance_eval do
      visit
      fill_out_user_form
      create_user_button.click
    end

    ::Pages::Users::Show.new(test: self, url: user_path(User.last)).instance_eval do
      check_main_elements_presence
      assert notice.text == 'User was successfully created.'
    end

    ::Pages::Users::Index.new.visit
    assert_text 'Bohdan Pohorilets'
  end

  test 'editing existing user' do
    User.new(first_name: 'Bohdan', last_name: 'Pohorilets').save

    ::Pages::Users::Edit.new(url: edit_user_url(User.first)).instance_eval do
      visit
      fill_out_user_form(first: 'First', last: 'Last')
      update_user_button.click
    end

    ::Pages::Users::Index.new(test: self).instance_eval do
      visit
      assert_text 'First Last'
    end
  end
end
