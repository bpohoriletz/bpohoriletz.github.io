module Pages
  module Users
    module Partials
      module UserForm
        def self.included(clazz)
          clazz.has_node :first_name,         '#user_first_name'
          clazz.has_node :last_name,          '#user_last_name'
        end

        def fill_out_user_form(first: 'Bohdan', last: 'Pohorilets')
          first_name.set(first)
          last_name.set(last)
        end
      end
    end
  end
end
