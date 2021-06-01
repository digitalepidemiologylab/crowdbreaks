require 'rails_helper'

RSpec.describe QuestionSequencesController, type: :controller do
  let!(:private_project) { FactoryBot.create(:project) }
  let!(:public_project) { FactoryBot.create(:project, :public) }
  let!(:private_project_link_only) { FactoryBot.create(:project, accessible_by_email_pattern: ["\\w@\\w"]) }

  let!(:user) { FactoryBot.create(:user, :confirmed, email: 'email@example.com') }
  let!(:user_epfl) { FactoryBot.create(:user, :confirmed, email: 'email@epfl.ch') }

  describe 'GET #show' do
    it 'dont show private projects by default' do
      get :show, params: { project_id: private_project.id }
      expect(subject).not_to have_http_status(:redirect)
    end

    it 'shows public projects' do
      get :show, params: { project_id: public_project.id }
      expect(subject).to render_template(:show)
    end

    it 'dont show private projects to signed in user' do
      sign_in user
      get :show, params: { project_id: private_project.id }
      expect(subject).to redirect_to(projects_path)
    end

    it 'shows public projects to signed in user' do
      sign_in user
      get :show, params: { project_id: public_project.id }
      expect(subject).to render_template(:show)
    end

    it 'show private project to signed in user if pattern matches' do
      sign_in user
      get :show, params: { project_id: private_project_link_only.id }
      expect(subject).to render_template(:show)
    end
  end
end
