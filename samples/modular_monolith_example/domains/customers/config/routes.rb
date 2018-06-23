module Customers
  Engine.routes.draw do
    # sessions
    get '/login', to: 'sessions#new', as: :login
    post '/login', to: 'sessions#create', as: :authenticate
    resources :sessions, only: [ :destroy ]

    resources :accounts
    resource  :locale, only: :update, constraints: { id: /(en|ua|ru)/ }
    resources :profiles, only: :update
    # Google API
    resource :oauth, only: [] do
      get :callback
      get :unlink
    end
  end
end
