Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "statuses#new"

  resources :statuses, only: [:show, :new, :create], path: "s"
end
