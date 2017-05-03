require "application_system_test_case"

class UsersCrudsTest < ApplicationSystemTestCase

  before do
    visit users_path
  end

  test "visiting the index" do
    visit users_cruds_url

    assert_selector "h1", text: "UsersCrud"
  end
end
