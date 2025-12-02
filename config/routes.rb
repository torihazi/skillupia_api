Rails.application.routes.draw do
  
  resources :users do
    get :setup, on: :collection
  end
  
end
