Rails.application.routes.draw do

  ActiveAdmin.routes(self)

  root 'pages#index'

  get 'test', to: 'pages#test'
  post 'test', to: 'pages#es_test'

  get 'mturk_tokens', to: 'pages#mturk_tokens'

  get 'react_test', to: 'pages#react_test'

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
