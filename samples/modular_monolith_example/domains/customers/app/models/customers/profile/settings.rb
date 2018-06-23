module Customers
  class Profile < ActiveRecord::Base
    module Settings
      SETTINGS = %w{locale start_hour end_hour encrypt}
      # METAPROGRAMMING MUST HAVE
      def method_missing( method_name, *arguments, &block )
        return settings[ method_name.to_s ] if SETTINGS.include?( method_name.to_s )
        super
      end

      def respond_to?( method_name, include_all = false )
        return true if SETTINGS.include?( method_name.to_s )
        return true if SETTINGS.include?( method_name.to_s[0..-2] ) && '=' == method_name.to_s[-1]
        super
      end
      # SETTERS & GETTERS
      SETTINGS.each do |method_name|
        # setter
        define_method method_name + '=' do |value|
          self.settings[ method_name ] = value
        end
        # getter
        define_method method_name do
          self.settings[ method_name ]
        end
      end
    end
  end
end
