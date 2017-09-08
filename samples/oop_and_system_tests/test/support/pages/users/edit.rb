require_relative '../base'
require_relative 'partials/user_form'

module Pages
  module Users
    class Edit < Pages::Base
      include Partials::UserForm

      has_node :update_user_button, '//input[@value = "Update User"]', :xpath
    end
  end
end
