module Customers
  class LocalesController < ApplicationController
    def update
      session[ :locale ] = params[ :id ]

      respond_to do |format|
        format.js{ render js: 'window.location.reload()' }
      end
    end
  end
end
