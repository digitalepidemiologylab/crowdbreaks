module Admin
  class QuestionSequencesController < BaseController
    authorize_resource class: false

    def new
    end

    def index
      @projects = Project.all
    end

    def show
      respond_to do |format|
        @project = Project.friendly.find(show_params[:id])
        format.html {
          @question_sequence = QuestionSequence.new(@project).load
          @user_id = current_or_guest_user.id
          @hit_id = show_params[:hitId]
          @tweet_id = FlaskApi.new.get_tweet(@project.es_index_name, user_id: @user_id)
          @mode = show_params[:mode]
          @mturk_instructions = MturkBatchJob.new.default_mturk_instructions
          @assignment_id = show_params[:assignmentId]
          @worker_id = show_params[:workerId]
          @preview_mode = show_params[:preview_mode] == 'true' ? true : false
          @notification = MturkNotification.new.success
          # @notification = MturkNotification.new.max_tasks_by_worker_reached
        }
        format.csv {
          send_data @project.to_csv, filename: "#{@project.title}-#{Time.current.strftime("%d-%m-%Y")}.csv"
        }
      end
    end

    def edit
      @project = Project.friendly.find(params[:id])
      if @project.results.count > 0
        flash[:warning] = "This question sequence is associated with existing answers to questions (results). Therefore certain fields cannot be modified as this would invalidate old data."
      end
      @question_sequence = QuestionSequence.new(@project).edit
    end

    def update
      project = Project.friendly.find(params[:id])
      transitions = question_sequence_params.fetch(:transitions).to_h
      questions = question_sequence_params.fetch(:questions).to_h
      
      QuestionSequence.new(project).update(questions, transitions)
      flash[:notice] = 'Successfully updated question sequence.'
      head :ok
    end

    def destroy
      project = Project.friendly.find(params[:id])
      if project.results.count > 0
        redirect_to(admin_question_sequences_path, alert: 'Cannot delete question sequence with existing answers to questions (results). Delete results or define a new project.')
      else
        QuestionSequence.new(project).destroy
        redirect_to(admin_question_sequences_path, notice: 'Successfully deleted question sequence.')
      end
    end
    

    private

    def show_params
      params.permit(:id, :hitId, :assignmentId, :workerId, :mode, :locale, :preview_mode, :no_work_available)
    end

    def question_sequence_params
      params.require(:question_sequence).permit(:questions => {}, :transitions => {})
    end
  end
end
