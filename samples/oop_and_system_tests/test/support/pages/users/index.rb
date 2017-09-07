require_relative '../base'

module Pages
  module Users
    class Index < Pages::Base
      has_node :new_user_link, 'a', :css, text: 'New User'

      private

      def http_path
        users_path
      end
    end
  end
end
