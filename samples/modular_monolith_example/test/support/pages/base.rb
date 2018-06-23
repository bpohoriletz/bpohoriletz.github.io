module Pages
  class Base
    Error = Class.new(StandardError)

    attr_reader :current_session
    attr_reader :http_path
    attr_reader :test
    delegate :assert, :assert_text, :take_screenshot, to: :test
    delegate :first, :assert_selector, to: :current_session

    def visit
      current_session.visit http_path
    end

    def self.has_node(method_name, selector, selector_type = :css, options = {})
      case selector_type
      when :css
        # Accessor
        define_method(method_name) do
          css_selector = @css_wrapper + ' ' + selector
          first(selector_type, css_selector.strip, options)
        end
        # Assertion
        define_method(method_name.to_s + '_present?') do
          css_selector = @css_wrapper + ' ' + selector
          assert_selector(selector_type, css_selector.strip, options)
        end
      when :xpath
        # Accessor
        define_method(method_name) do
          first(selector_type, selector, options)
        end
        # Assertion
        define_method(method_name.to_s + '_present?') do
          assert_selector(selector_type, selector, options)
        end
      else
        fail Error, "Unknown selector type #{selector_type}"
      end
    end

    private

    # initialize with Capybara session
    def initialize(test: :test_not_set, url: http_path, css_wrapper: ' ', current_session: Capybara.current_session)
      @css_wrapper = css_wrapper
      @current_session = current_session
      @http_path = url
      @test = test
    end
  end
end
