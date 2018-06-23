module Customers
  class OauthsController < ApplicationController
    skip_before_action :require_account, only: :callback
    before_action :require_code, only: :callback

    # refresh token from Google
    # Parameters: {"code"=>"4/_kpFZkKY7-8FqHCy_Z5Tnab6nu8uj4d_yJevpGyFPog"}
    def callback
      # TOFIX security!
      refresh_token = GoogleCalendar::Connection.exchange_acces_token_for_refresh( access_token: params.require( :code ) )

      authentication = Account.build_google_authentication( refresh_token: refresh_token )
      if authentication.save
        AccountSession.create( authent: authentication.account )
        redirect_to account_url(0)
      else
        flash[ :error ] = 'views.login.google_failure'
        redirect_to login_url
      end
    end

    def unlink
      current_account.authentications.map( &:destroy )

      redirect_to account_path(0)
    end

    private

    def require_code
      redirect_to login_url if params[ :code ].blank?
    end
  end
end
