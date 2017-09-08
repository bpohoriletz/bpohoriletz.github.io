require_relative '../base'
require_relative 'partials/user_form'

module Pages
  module Users
    class New < Pages::Base
      include Partials::UserForm

      has_node :create_user_button, '//input[@value = "Create User"]', :xpath

      private

      def http_path
        new_user_path
      end
    end
  end
end
