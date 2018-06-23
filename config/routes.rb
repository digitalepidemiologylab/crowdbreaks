Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  root 'pages#index'

  namespace :admin do
    resources :projects, except: [:show, :index]
  end

  scope :api do
    controller :apis do
      post 'vaccine_sentiment', action: 'vaccine_sentiment'
      post 'update_visualization', action: 'update_visualization'
      post 'update_sentiment_map', action: 'update_sentiment_map'
      get 'set_config', action: 'set_config'
      get 'stream_status', action: 'stream_status'
      get 'stream_data', action: 'stream_data'
      post 'get_leadline', action: 'get_leadline'
      post 'question_sequence_end', action: 'question_sequence_end'
      get 'get_user_activity_data', action: 'get_user_activity_data'
    end
  end

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do |locale|
    devise_for :users, controllers: { registrations: 'users/registrations' }
    get 'about', to: 'pages#about'
    get 'privacy', to: 'pages#privacy'
    get 'terms_of_use', to: 'pages#terms_of_use'
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
      get 'current_streams', to: 'manage_pages#current_streams'
      get 'monitor_streams', to: 'manage_pages#monitor_streams'
      get 'sentiment_analysis', to: 'manage_pages#sentiment_analysis'
      get 'sentiment_analysis_playground', to: 'manage_pages#sentiment_analysis_playground'
      get 'sentiment_analysis_chart', to: 'manage_pages#sentiment_analysis_chart'
      get 'sentiment_analysis_map', to: 'manage_pages#sentiment_analysis_map'
      get 'user_activity', to: 'manage_pages#user_activity'
      resources :mturk_batch_jobs do
        resources :tasks
        get 'submit'
      end
      resources :elasticsearch_indexes
    end
  end


  # errors
  %w( 404 422 500 ).each do |status_code|
    match status_code, :to => "errors#show", :via => :all, :status_code => status_code
  end
end
