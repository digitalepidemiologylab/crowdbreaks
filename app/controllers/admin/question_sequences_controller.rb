module Admin
  class QuestionSequencesController < BaseController
    load_and_authorize_resource :project, parent: false

    def new
      @names = Project.primary.pluck(:name)
    end

    def index
      @projects = @projects.order({last_question_sequence_created_at: :desc}).primary.page(params[:page]).per(10)
    end

    def show
      respond_to do |format|
        format.html {
          @question_sequence = QuestionSequence.new(@project).load
          @user_id = current_or_guest_user.id
          @hit_id = show_params[:hitId]
          @tweet_id = @project.get_tweet(user_id: @user_id)
          @mode = show_params[:mode]
          @mturk_instructions = MturkBatchJob.new.default_mturk_instructions
          @assignment_id = show_params[:assignmentId]
          @worker_id = show_params[:workerId]
          @preview_mode = show_params[:preview_mode] == 'true' ? true : false
          @notification = MturkNotification.new.success
        }
        format.csv {
          send_data @project.qs_to_csv, filename: "#{@project.name}-#{Time.current.strftime("%d-%m-%Y")}.csv"
        }
      end
    end

    def edit
      if @project.results.count > 0
        flash[:warning] = "This question sequence is associated with existing answers to questions (results). Therefore certain fields cannot be modified as this would invalidate old data."
      end
      @question_sequence = QuestionSequence.new(@project).edit
    end

    def update
      transitions = question_sequence_params.fetch(:transitions).to_h
      questions = question_sequence_params.fetch(:questions).to_h
      QuestionSequence.new(@project).update(questions, transitions)
      flash[:notice] = 'Successfully updated question sequence.'
      head :ok
    end

    def destroy
      if @project.results.count > 0
        redirect_to(admin_question_sequences_path, alert: 'Cannot delete question sequence with existing answers to questions (results). Delete results first.')
      elsif @project.primary?
        redirect_to(admin_question_sequences_path, alert: 'Cannot delete primary question sequence. Remove project in admin/projects.')
      elsif @project.local_batch_jobs.count > 0
        redirect_to(admin_question_sequences_path, alert: 'Cannot delete primary question sequence. Delete associated local batch jobs first.')
      elsif @project.mturk_batch_jobs.count > 0
        redirect_to(admin_question_sequences_path, alert: 'Cannot delete primary question sequence. Delete associated mturk batch jobs first.')
      else
        QuestionSequence.new(@project).destroy
        @project.destroy
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
