module Customers
  class ProfilesController < ApplicationController
    # PUT profiles/:id
    def update
      # TOFIX security
      profile = Profile.find( params[ :id ] )
      profile.update_attributes( profile_params )

      respond_to do |format|
        format.json { respond_with_bip( profile ) }
      end
    end

    private

    def profile_params
      params.require( :profile ).permit( :google_login, :locale, :start_hour, :end_hour )
    end
  end
end
