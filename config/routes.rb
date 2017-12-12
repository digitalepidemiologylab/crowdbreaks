Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  root 'pages#index'

  get 'test', to: 'pages#test'
  post 'test', to: 'pages#es_test'

  namespace :admin do
    resources :projects, except: [:show, :index]
  end

  scope :api do
    post 'vaccine_sentiment', to: 'apis#vaccine_sentiment'
    post 'update_visualization', to: 'apis#update_visualization'
    get 'set_config', to: 'apis#set_config'
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
      get '/', to: redirect('manage/dashboard')
      get 'dashboard', to: 'manage_pages#dashboard'
      get 'streaming', to: 'manage_pages#streaming'
      get 'status_streaming', to: 'manage_pages#status_streaming'
      resources :mturk_batch_jobs do
        resources :tasks
        get 'submit'
      end
    end
  end
end
