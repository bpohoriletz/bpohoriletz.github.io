require_relative '../base'

module Pages
  module Users
    class Edit < Pages::Base
      has_node :first_name,         '#user_first_name'
      has_node :last_name,          '#user_last_name'
      has_node :update_user_button, '//input[@value = "Update User"]', :xpath
    end
  end
end
