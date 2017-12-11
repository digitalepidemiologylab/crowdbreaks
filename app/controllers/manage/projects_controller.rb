module Manage
  class ProjectsController < BaseController
    def new
      @project = Project.new
    end

    def create
      puts "hello"
    end
  end
end
