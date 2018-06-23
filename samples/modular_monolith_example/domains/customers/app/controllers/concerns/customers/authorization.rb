module Customers
  module Authorization
    extend ActiveSupport::Concern

    included do
      before_action :log_additional_data

      helper_method :current_account_session, :current_account
    end


    private

    def set_locale
      I18n.locale = current_account.locale || I18n.default_locale
    end

    def log_additional_data
      request.env["exception_notifier.exception_data"] = {
        :person => current_account && current_account.name
      }
    end

    # authentication
    def current_account_session
      Customers::WebSession.find
    end

    def current_account
      current_account_session&.account
    end

    def require_account
      return true if current_account.present?
      store_location
      flash[ :warning ] = t( 'views.login.required' )
      redirect_to customers.login_url
    end

    def require_no_account
      return true if current_account.blank?
      store_location
      flash[ :warning ] = t( 'views.nologin.required' )
      redirect_to main_app.root_url
    end

    def store_location
      session[ :return_to ] = request.original_url
    end

    def redirect_back_or_default(default)
      redirect_to( session[ :return_to ] || default )
      session[ :return_to ] = nil
    end

    def not_authorized
      flash[ :error ] = 'global.no_access'
      redirect_back( fallback_location: main_app.root_path )
    end
  end
end
