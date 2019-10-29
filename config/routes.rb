Rails.application.routes.draw do
  root 'pages#index'

  # cables
  mount ActionCable.server => '/cable'

  namespace :admin do
    get '/', to: redirect('admin/dashboard')
    get 'dashboard', to: 'admin_pages#dashboard'
    resources :projects
    resources :question_sequences, except: [:create]
    resources :users
    resources :results, except: [:update] do
      post 'flag', on: :member
    end
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
      get 'get_user_activity_data', action: 'get_user_activity_data'
      post 'get_stream_graph_data', action: 'get_stream_graph_data'
    end
  end

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do |locale|
    devise_for :users, controllers: { registrations: 'users/registrations', sessions: 'users/sessions' }
    get 'about', to: 'pages#about'
    get 'privacy', to: 'pages#privacy'
    get 'terms_of_use', to: 'pages#terms_of_use'
    resources :projects, only: [:show, :index] do
      resource :question_sequence, only: [:show, :create] do
        post 'final'
      end
    end
    resources :local_batch_jobs, only: [:show] do
      post 'final'
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
      get 'monitor_streams', to: 'manage_pages#monitor_streams'
      get 'sentiment_analysis', to: 'manage_pages#sentiment_analysis'
      get 'sentiment_analysis_playground', to: 'manage_pages#sentiment_analysis_playground'
      get 'sentiment_analysis_chart', to: 'manage_pages#sentiment_analysis_chart'
      get 'sentiment_analysis_map', to: 'manage_pages#sentiment_analysis_map'
      get 'user_activity', to: 'manage_pages#user_activity'

      # mturk
      resources :mturk_batch_jobs do
        resources :tasks
        resources :mturk_tweets, only: [:index] do
          get 'update_availability', on: :collection
        end
        get 'submit', on: :member
        get 'clone', on: :collection
      end
      resources :mturk_workers, only: [:index] do
        post 'blacklist', on: :member
        post 'block', on: :member
        get 'submit_block', on: :member
        post 'manual_review_status', on: :member
        get 'review', on: :member
        post 'review_assignment', on: :collection
        get 'refresh_review_status', on: :collection
      end
      resources :mturk_cached_hits, path: 'mturk_hits' do
        get 'update_cached_hits', on: :collection
        get 'clear_all', on: :collection
      end
      resources :mturk_reviewable_hits, only: [:index, :show] do
        get 'link_to_results'
        post 'multi_review', on: :collection
        post 'accept', on: :member
        post 'reject', on: :member
      end

      # elasticsearch
      resources :elasticsearch_indexes
      resources :local_batch_jobs, as: 'manage_local_batch_jobs' do
        resources :local_tweets, only: [:index]
      end
    end
  end

  # errors
  %w( 404 422 500 ).each do |status_code|
    match status_code, :to => "errors#show", :via => :all, :status_code => status_code
  end
end
