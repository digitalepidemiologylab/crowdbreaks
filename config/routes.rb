Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
            registrations: 'users/registrations'
  }
  root 'pages#index'
  resources :projects, only: [:index, :show]
  get '/projects', to: 'projects#index'
end
