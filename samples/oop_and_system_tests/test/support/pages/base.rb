module Pages
  class Base
    Error = Class.new(StandardError)
    include Rails.application.routes.url_helpers

    attr_reader :test
    attr_reader :current_session
    attr_reader :http_path
    delegate :first, :assert_selector, to: :current_session
    delegate :assert, :assert_text, to: :test

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
      @current_session = current_session
      @http_path = url
      @test = test
      @css_wrapper = css_wrapper
    end
  end
end
