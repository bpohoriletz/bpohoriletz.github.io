require_relative '../base'

module Pages
  module Users
    class New < Pages::Base
      has_node :first_name,         '#user_first_name'
      has_node :last_name,          '#user_last_name'
      has_node :create_user_button, '//input[@value = "Create User"]', :xpath

      private

      def http_path
        new_user_path
      end
    end
  end
end
