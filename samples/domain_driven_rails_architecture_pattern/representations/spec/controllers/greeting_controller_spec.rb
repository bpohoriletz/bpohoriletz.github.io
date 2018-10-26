# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GreetingController, type: :controller do
  context '#welcome' do
    it 'responds to the action' do
      get :welcome
      expect( response ).to have_http_status( :success )
    end

    it 'renders welcome message' do
      get :welcome
      expect( response.body ).to match( /Welcome/ )
    end
  end
end
