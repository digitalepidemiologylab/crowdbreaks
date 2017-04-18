Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
            registrations: 'users/registrations'
  }

  root 'pages#index'

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do |locale|
    resources :projects, only: [:index]
    resources :questions, only: [] do
      resources :results, only: [:create, :new]
    end
  end
end
