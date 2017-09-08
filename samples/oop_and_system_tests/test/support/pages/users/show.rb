require_relative '../base'

module Pages
  module Users
    class Show < Pages::Base
      has_node :notice, '#notice'
      has_node :edit_user_link, 'a', :css, text: 'Edit'
      has_node :back_link, '//a[text()="Back"]', :xpath

      def check_main_elements_presence
        notice_present?
        edit_user_link_present?
        back_link_present?
      end
    end
  end
end
