require 'authlogic'

module Customers
  class Account < ActiveRecord::Base
    NotAuthorized = Class.new( StandardError )
    # CONNECTIONS
    has_many :authentications, dependent: :destroy
    accepts_nested_attributes_for :authentications
    has_one :profile, dependent: :destroy
    accepts_nested_attributes_for :profile

    # VALIDATIONS
    validates :email, presence: true
    validates_associated :profile

    # PLUGINS
    acts_as_authentic do |config|
      config.logged_in_timeout = 1.hour
      # TOFIX
      config.session_class = WebSession
    end

    # DELEGATIONS
    delegate :name, :admin?, :locale, to: :profile
    delegate :calendar, :calendar_events, to: :google_client, prefix: :google

    def safe_destroy( flash )
      if admin?
        flash.now[ :error ] = 'activerecord.models.account.messages.delete_admin'
      else
        if destroy
          flash.now[ :notice ] = [ 'activerecord.models.account.messages.deleted', name: name ]
        else
          flash.now[ :warning ] = [ 'activerecord.models.account.messages.delete_failed', name: name ]
        end
      end

      return flash
    end

    def self.build_google_authentication( refresh_token: )
      connection = self.new.google_client( refresh_token: refresh_token )
      email = connection.email
      profile = Profile.where( google_login: email ).first
      return :profile_not_found if profile.blank?

      # TOFIX link authentication to profile
      authentication = Authentication.where( account_id: profile.account.id, provider: 'google' ).first_or_initialize
      authentication.uid = refresh_token

      return authentication
    end

    def google_client( refresh_token: nil )
      refresh_token = refresh_token || google_authentication_token

      ::GoogleCalendar::Connection.new( refresh_token: refresh_token )
    end

    private

    def google_authentication_token
      # TOFIX - security, profile.google_login
      authentications.first&.uid
    end
  end
end

# == Schema Information
#
# Table name: accounts
#
#  id                  :integer          not null, primary key
#  email               :string           not null
#  crypted_password    :string           not null
#  password_salt       :string           not null
#  persistence_token   :string           not null
#  single_access_token :string           not null
#  perishable_token    :string           not null
#  login_count         :integer          default(0), not null
#  failed_login_count  :integer          default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string
#  last_login_ip       :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_accounts_on_email  (email) UNIQUE
#
