# frozen_string_literal: true

# TOFIX: delete
class GreetingController < ActionController::Base
  include ::ApplicationController
  # GET /
  def welcome
    respond_to do |format|
      format.html { render plain: "<h1>Welcome traveller ##{UUID.new.generate}!</h1>" }
    end
  end
end
