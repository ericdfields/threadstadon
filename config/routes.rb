Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  
#   constraints(host: 'threadstadon.io') do
#     get '/:param', to: redirect('https://threadstodon.io/%{param}')
#   end
  
  # Defines the root path route ("/")
  root "statuses#new"

  resources :statuses, only: [:show, :new, :create], path: "s"
end
