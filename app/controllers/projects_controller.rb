class ProjectsController < ApplicationController
  def index
    @projects = Project.all
    @first_questions = {}
    # @projects.each do |project|
    #   @first_questions[project.id] = project.transitions.find_by(:from_question => nil)
    # end
  end
end
