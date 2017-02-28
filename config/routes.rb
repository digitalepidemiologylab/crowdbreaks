Rails.application.routes.draw do
  root 'pages#index'
  resources :projects, path: 'projects', only: [:index, :show]
  get '/projects', to: 'projects#index'
end
