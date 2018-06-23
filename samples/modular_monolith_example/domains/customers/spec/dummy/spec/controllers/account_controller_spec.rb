require_relative '../rails_helper'

RSpec.describe Customers::AccountsController, type: :controller do
  routes { Customers::Engine.routes }

  it 'should respond to new action' do
    login_as_administrator
    get :new
    expect( response ).to have_http_status( :success )
  end

  it 'should not create invalid account' do
    login_as_administrator
    post :create, params: { account: { email: 'test@test.ua' } }, xhr: true
    expect( response ).to have_http_status( :success )
  end

  it 'should respond to index action' do
    login_as_administrator
    get :index
    expect( response ).to have_http_status( :success )
  end

  it 'should respond to show action' do
    login_as_administrator
    get :show, params: { id: -1 }
    expect( response ).to have_http_status( :success )
  end

  it 'should respond to edit action' do
    allow( Customers::Account ).to receive( :find ).
                                   and_return( instance_spy( Customers::Account ) )

    login_as_administrator
    get :edit, params: { id: -1 }
    expect( response ).to have_http_status( :success )
  end

  it 'should respond to update action' do
    allow( Customers::Account ).to receive( :find ).
                                   and_return( instance_spy( Customers::Account ) )

    login_as_administrator
    put :update, params: { id: -1, account: { email: 'test@test.ua' } }, xhr: true
    expect( response ).to have_http_status( :success )
  end

  it 'should show errors for invalid account params' do
    allow( Customers::Account ).to receive( :find ).
                                   and_return( instance_spy( Customers::Account ) )

    login_as_administrator
    put :update, params: { id: -1, account: { email: 'test' } }, xhr: true
    expect( response ).to have_http_status( :success )
  end

  it 'should respond to destroy action' do
    allow( Customers::Account ).to receive( :find ).
                                   and_return( instance_spy( Customers::Account ) )

    login_as_administrator
    delete :destroy, params: { id: -1 }, xhr: true
    expect( response ).to have_http_status( :success )
  end
end
