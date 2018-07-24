module Admin
  class QuestionSequencesController < BaseController
    def new
    end

    def index
      @projects = Project.all
    end

    def show
      @project = Project.friendly.find(params[:id])
      @question_sequence = QuestionSequence.new(@project).create
      @translations = I18n.backend.send(:translations)[I18n.locale][:question_sequences]
      @user_id = current_or_guest_user.id
      @tweet_id = FlaskApi.new.get_tweet(@project.es_index_name, user_id: @user_id)
      @mode = params[:mode]
      @mturk_instructions = MturkBatchJob.new.default_mturk_instructions
      @hit_id = params[:hitId]
      @assignment_id = params['assignmentId']
      @worker_id = params['workerId']
    end

    def create
      project = Project.friendly.find(question_sequence_params[:projectId])
      transitions = question_sequence_params.fetch(:transitions).to_h
      questions = question_sequence_params.fetch(:questions).to_h

      # make sure no survey data is lost
      raise 'Project has existing answers to questions. Aborting.' if project.results.count > 0

      # delete all pre-existing questions, answers and transitions
      delete_question_sequence(project)

      # create new questions and answers
      if create_question_sequence(project, questions, transitions)
        flash[:notice] = 'Successfully updated question sequence.'
        head :ok
      else
        head :bad_request
      end
    end

    def edit
      @project = Project.friendly.find(params[:id])
      if @project.results.count > 0
        redirect_to(admin_question_sequences_path, alert: 'Cannot modify a question sequence with existing answers to questions (results). Delete results or define a new project.')
      end
      @question_sequence = QuestionSequence.new(@project).edit
    end

    def update
    end

    def destroy
      project = Project.friendly.find(params[:id])
      if project.results.count > 0
        redirect_to(admin_question_sequences_path, alert: 'Cannot delete question sequence with existing answers to questions (results). Delete results or define a new project.')
      else
        delete_question_sequence(project)
        redirect_to(admin_question_sequences_path, notice: 'Successfully deleted question sequence.')
      end

    end

    private

    def delete_question_sequence(project)
      # delete any existing answers or questions
      project.questions.each do |q|
        # deletes answers and QuestionAnswers on join table
        Answer.where(id: q.answers.pluck(:id)).destroy_all
      end
      project.questions.destroy_all

      # delete any existing transitions
      project.transitions.destroy_all
    end

    def create_question_sequence(project, questions, transitions)
      answer_mapping = {}
      question_mapping = {}
      success = true
      questions.each do |q_id, q|
        question = Question.new(project: project, question: q[:question])
        q[:answers].each_with_index do |a, idx|
          answer = Answer.new(answer: a[:answer], label: a[:label], color: a[:color])
          question.question_answers.build(answer: answer, order: idx)
        end
        success = success && question.save
        question_mapping[q[:id]] = question.id
        question.answers.each_with_index do |a, idx|
          answer_mapping[q[:answers][idx][:id].to_i] = a.id
        end
      end

      # create new transitions
      transitions.to_a.each do |id, t|
        from_question = nil
        if t[:from_question] != 'start'
          from_question = question_mapping[t[:from_question].to_i]
        end
        answer = nil
        if t[:transition][:answer] != ""
          answer = answer_mapping[t[:transition][:answer].to_i]
        end
        transition = Transition.create(from_question_id: from_question,
                                       to_question_id: question_mapping[t[:transition][:to_question].to_i],
                                       answer_id: answer,
                                       project: project)
        success = success && transition.persisted?
      end
      success
    end

    def question_sequence_params
      params.require(:question_sequence).permit(:projectId, :questions => {}, :transitions => {})
    end

  end
end
