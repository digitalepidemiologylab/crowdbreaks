Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
            registrations: 'users/registrations'
  }

  root 'pages#index'

  resources :projects, only: [:index]
  resources :questions, only: [] do
    resources :results, only: [:create, :new]
  end
end
