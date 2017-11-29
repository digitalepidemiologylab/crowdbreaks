Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  root 'pages#index'

  get 'test', to: 'pages#test'
  post 'test', to: 'pages#es_test'

  scope :api do
    post 'vaccine_sentiment', to: 'projects#vaccine_sentiment'
  end

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do |locale|
    devise_for :users, controllers: { registrations: 'users/registrations' }
    get 'about', to: 'pages#about'
    resources :projects, only: [:show, :index] do
      resource :question_sequence, only: [:show, :create]
    end

    namespace :mturk do
      resource :question_sequence, only: [:show, :create] do
        post 'final'
      end
    end

    namespace :manage do
      root to: "manage_pages#index"
      resources :mturk_batch_jobs do
        resources :tasks
        get 'submit'
      end
    end
  end
end
