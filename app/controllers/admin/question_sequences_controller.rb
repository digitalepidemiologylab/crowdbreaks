module Admin
  class QuestionSequencesController < BaseController
    def new
    end

    def index
      @projects = Project.all
    end

    def create
    end

    def edit
      @project = Project.friendly.find(params[:id])
      @question_sequence = QuestionSequence.new(@project).create
    end

    def update
    end

    def destroy
    end

    private

  end
end
