Rails.application.routes.draw do
  # homepage
  root 'homepage#index'

  mount Customers::Engine => "/customers", as: 'customers'
end
