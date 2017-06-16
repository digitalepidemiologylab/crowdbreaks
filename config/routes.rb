Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  devise_for :users, controllers: { registrations: 'users/registrations' }

  root 'pages#index'

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do |locale|
    resources :projects, only: [:show, :index]
    scope "(:project_id)" do
      resource :question_sequence, only: [:show, :create]
      root to: 'projects#show'
      # get :question_seq, to: 'QuestionSequences#show'
      # post :question_seq, to: 'QuestionSequences#create'
    end
  end
end
