module Customers
  class Profile < ActiveRecord::Base
    include Settings
    # ASSOCIATIONS
    belongs_to :account
    # VALIDATIONS
    validates_presence_of   :first_name, :last_name
    validates_uniqueness_of :google_login
    # SERIAL
    serialize :settings, Hash

    def name
      [ first_name, middle_name, last_name ].join( ' ' )
    end

    def admin?
      100 == permissin_level
    end
  end
end

# == Schema Information
#
# Table name: profiles
#
#  id              :integer          not null, primary key
#  first_name      :string           not null
#  middle_name     :string
#  last_name       :string           not null
#  permissin_level :integer
#  account_id      :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  settings        :text
#  google_login    :string
#
# Indexes
#
#  index_profiles_on_account_id    (account_id)
#  index_profiles_on_google_login  (google_login) UNIQUE
#
