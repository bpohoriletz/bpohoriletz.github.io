module Customers
  class AccountsController < ApplicationController
    rescue_from Account::NotAuthorized, with: :not_authorized
    before_action :require_admin, except: [ :show ]

    # GET /accounts/new
    def new
      @account = Account.new
      @account.build_profile

      respond_to do |format|
        format.html
        format.js{ render 'new', :layout => 'customers/ajax' }
      end
    end

    # POST /accounts
    def create
      @account = Account.new( account_params )
      @account.password = params[ :account ][ :password ]
      @account.password_confirmation = params[ :account ][ :password_confirmation ]

      respond_to do |format|
        if @account.save
          format.js{ render 'index', :layout => 'customers/ajax', locals: { accounts: Account.all } }
        else
          format.js{ render action: :new, :layout => 'customers/ajax' }
        end
      end
    end

    # GET /accounts
    def index
      accounts = Account.all.order( :id )

      respond_to do |format|
        format.html{ render 'index', locals: { accounts: accounts } }
        format.js{ render 'index', :layout => 'customers/ajax', locals: { accounts: accounts } }
      end
    end

    # Account Cabinet
    # GET /accounts/:id
    def show

      respond_to do |format|
        format.html
        format.js{ render 'show', :layout => 'customers/ajax' }
      end
    end

    # GET /accounts/edit/:id
    def edit
      @account = Account.find( params[ :id ] )

      respond_to do |format|
        format.html
        format.js{ render 'edit', :layout => 'customers/ajax' }
      end
    end

    # PUT /accounts/:id
    def update
      @account = Account.find( params[ :id ] )

      respond_to do |format|
        if @account.update_attributes( account_params )
          flash.now[ :notice ] = [ 'activerecord.models.account.messages.update_success', name: @account.name ]
          format.js{ render 'index', :layout => 'customers/ajax', locals: { accounts: Account.all } }
        else
          flash.now[ :warning ] = 'activerecord.models.account.messages.update_failed'
          format.js{ render action: :edit, :layout => 'customers/ajax' }
        end
      end
    end

    # PUT /accounts/:id
    def destroy
      @account = Account.find( params[ :id ] )
      @account.safe_destroy( flash )

      respond_to do |format|
        format.js{ render 'index', :layout => 'customers/ajax', locals: { accounts: Account.all } }
      end
    end

    private

    def account_params
      params.require( :account ).permit( :email, profile_attributes: [ :first_name, :middle_name, :last_name ] )
    end

    def require_admin
      fail Account::NotAuthorized unless current_account.admin?
    end
  end
end
