require_relative '../base'

module Pages
  module Users
    class Show < Pages::Base
      has_node :notice, '#notice'
      has_node :edit_user_link, 'a', :css, text: 'Edit'
      has_node :back_link, '//a[text()="Back"]', :xpath
    end
  end
end
