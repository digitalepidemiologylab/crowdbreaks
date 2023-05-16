require 'rails_helper'

RSpec.describe ProjectsController, type: :controller do

  let!(:public_project) { FactoryBot.create(:project, :public) }
  let!(:private_project) { FactoryBot.create(:project) }
  let!(:user) { FactoryBot.create(:user, :confirmed, email: 'email@example.com') }
  let!(:incorrect_user) { FactoryBot.create(:user, :confirmed, email: 'incorrect@example.com') }
  let!(:epfl_user) { FactoryBot.create(:user, :confirmed, email: 'test@epfl.ch') }

  let!(:public_project2) { FactoryBot.create(:project, :public, accessible_by_email_pattern: ['email@example.com']) }
  let!(:public_project_epfl) { FactoryBot.create(:project, :public, accessible_by_email_pattern: ["\\w@epfl.ch"]) }

  xdescribe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to render_template("index")
    end

    it "only shows public projects" do
      get :index
      expect(assigns(:projects)).to include public_project
      expect(assigns(:projects)).not_to include private_project
    end

    it "only shows public projects without email pattern for non signed in user" do
      get :index
      expect(assigns(:projects)).not_to include public_project2
      expect(assigns(:projects)).to include public_project
    end

    it "shows public projects with correct email pattern for signed in user" do
      sign_in user
      get :index
      expect(assigns(:projects)).to include public_project2
      expect(assigns(:projects)).not_to include private_project
    end

    it "doesnt show public projects with incorrect email pattern for signed in user" do
      sign_in incorrect_user
      get :index
      expect(assigns(:projects)).not_to include public_project2
      expect(assigns(:projects)).not_to include private_project
    end

    it "email pattern works correctly for signed in users" do
      sign_in epfl_user
      get :index
      expect(assigns(:projects)).to include public_project_epfl
      expect(assigns(:projects)).not_to include public_project2
    end
  end
end
