module Customers
  class SessionsController < ActionController::Base
    include Authorization
    before_action :require_no_account, :only => [:new, :create]
    before_action :require_account, :only => :destroy

    # GET /login
    def new
      params[ :account_session ] = {}

      respond_to do |format|
        format.html
      end
    end

    # POST /login
    def create
      web_session = WebSession.new( account_session_params.to_h )
      if web_session.save
        set_google_calendar_token
        redirect_back_or_default main_app.root_url
      else
        flash.now[ :warning ] = t( 'views.login.failure' )
        respond_to do |format|
          format.html{ render action: :new }
        end
      end
    end

    # DELETE account_sessions/:id
    def destroy
      current_account_session.destroy
      redirect_back_or_default login_url
    end

    private

    def set_google_calendar_token
      return true if current_account.authentications.blank?
      session[:access_token] = current_account.authentications.first.uid
    end

    def account_session_params
      params.require( :account_session ).permit( :email, :password, :remember_me )
    end
  end
end
