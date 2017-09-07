module Pages
  class Base
    Error = Class.new(StandardError)
    attr_reader :current_session
    attr_reader :url

    def self.has_node(method_name, selector, default_selector = :css, options = {})
      case default_selector
      when :css
        define_method(method_name) do
          css_selector = @css_wrapper + ' ' + selector
          current_session.first(default_selector, css_selector.strip, options)
        end
      when :xpath
        # XPATH accessor
        define_method(method_name) do
          current_session.first(default_selector, selector, options)
        end
      else
        fail Error, "Unknown selector #{default_selector}"
      end
    end

    private

    # initialize with Capybara session
    def initialize(url:, css_wrapper: ' ', current_session: Capybara.current_session)
      @current_session = current_session
      @url = url
      @css_wrapper = css_wrapper
    end
  end
end
