require_relative '../rails_helper'

RSpec.describe Customers::LocalesController, type: :controller do
  routes { Customers::Engine.routes }

  it 'should respond to update action' do
    login
    get :update, params: { id: 'ua', use_route: :customers }, xhr: :true
    expect( response ).to have_http_status( :success )
  end
end
