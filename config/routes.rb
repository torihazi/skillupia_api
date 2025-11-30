Rails.application.routes.draw do
  
  resource :users do
    get :setup, on: :collection
  end
  
end
