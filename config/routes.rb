Rails.application.routes.draw do

  ActiveAdmin.routes(self)



  root 'pages#index'

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do |locale|
    devise_for :users, controllers: { registrations: 'users/registrations' }
    get 'about', to: 'pages#about'
    resources :projects, only: [:show, :index]
    scope "(:id)" do
      root to: 'projects#show'
      resource :question_sequence, only: [:show, :create]
    end
  end
end
