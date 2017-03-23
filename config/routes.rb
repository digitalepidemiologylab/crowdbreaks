Rails.application.routes.draw do
  devise_for :users
  root 'pages#index'
  resources :projects, path: 'projects', only: [:index, :show]
  get '/projects', to: 'projects#index'
end
