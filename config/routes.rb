Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  devise_for :users, controllers: { registrations: 'users/registrations' }

  root 'pages#index'

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do |locale|
    resources :projects, only: [:show, :index]
    scope "(:project_id)" do
      root to: 'projects#show'
      resource :question_sequence, only: [:show, :create]
    end
  end
end
