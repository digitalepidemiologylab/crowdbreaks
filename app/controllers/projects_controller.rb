class ProjectsController < ApplicationController
  def index
    @projects = Project.all
    @first_questions = {}
  end

  def show
    redirect_to question_sequence_path(@project)
  end
end
