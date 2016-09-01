Rails.application.routes.draw do
  root "boards#index"
  resources :boards
end
