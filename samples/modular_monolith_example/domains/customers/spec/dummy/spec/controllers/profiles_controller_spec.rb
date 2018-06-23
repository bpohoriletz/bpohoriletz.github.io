require_relative '../rails_helper'

RSpec.describe Customers::ProfilesController, type: :controller do
  routes { Customers::Engine.routes }

  it 'should update profile when valid params passed' do
    allow_any_instance_of( described_class  ).to receive( :respond_with_bip )
    allow( Customers::Profile ).to receive( :find ).
                                   and_return( instance_spy( Customers::Profile ) )

    login
    get :update, params: { id: -1, profile: { locale: :en } }, xhr: true
    expect( response ).to have_http_status( :success )
  end

  it 'should return error when invalid params passed' do
    allow( Customers::Profile ).to receive( :find ).
                                   and_return( instance_spy( Customers::Profile ) )

    login
    expect{ get :update, params: { id: -1 }, xhr: true }.to raise_error ActionController::ParameterMissing
  end
end
