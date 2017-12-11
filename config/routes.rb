Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  root 'pages#index'

  get 'test', to: 'pages#test'
  post 'test', to: 'pages#es_test'

  scope :api do
    post 'vaccine_sentiment', to: 'projects#vaccine_sentiment'
    post 'update_visualization', to: 'projects#update_visualization'
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

    scope module: 'manage', path: 'manage' do
      get 'dashboard', to: 'manage_pages#dashboard'
      get 'streaming', to: 'manage_pages#streaming'
      get 'status_streaming', to: 'manage_pages#status_streaming'
      resources :mturk_batch_jobs do
        resources :tasks
        get 'submit'
      end
      resource :projects, only: [:new, :create], controller: 'projects'
    end
  end
end
