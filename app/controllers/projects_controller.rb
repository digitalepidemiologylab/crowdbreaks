class ProjectsController < ApplicationController
  before_action :set_project, :only => [:show]

  def index
    @projects = Project.all
  end

  def show
    redirect_to question_sequence_path(@project)
  end

  private

  def set_project
    return unless params[:id]
    @project = Project.friendly.find(params[:id])
  end
end
