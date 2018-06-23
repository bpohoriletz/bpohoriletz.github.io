Rails.application.routes.draw do
  root 'application#index'

  mount Customers::Engine => "/customers", as: 'customers'
end
