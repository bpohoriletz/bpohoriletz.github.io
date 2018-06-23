require_relative '../rails_helper'

RSpec.describe Customers::OauthsController, type: :controller do
  routes { Customers::Engine.routes }

  describe "GET #callback" do
    it "returns http redirect if the token is empty" do
      login
      get :callback
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET #unlink" do
    it "returns http redirect for unknown account" do
      login
      get :unlink
      expect(response).to have_http_status(:redirect)
    end
  end

end
