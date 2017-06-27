class ProjectsController < ApplicationController
  before_action :set_project

  def index
    @projects = Project.all
    @first_questions = {}
  end

  def show
    redirect_to question_sequence_path(@project)
  end
end
