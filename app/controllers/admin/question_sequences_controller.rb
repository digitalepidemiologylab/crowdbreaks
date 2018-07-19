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
      if @project.results.count > 0
        redirect_to(admin_question_sequences_path, alert: 'Cannot modify a question sequence with existing answers to questions. Delete answers or define a new project.')
      end
      @question_sequence = QuestionSequence.new(@project).edit
    end

    def update
      project = Project.friendly.find(params[:id])
      transitions = question_sequence_params.fetch(:transitions).to_h
      questions = question_sequence_params.fetch(:questions).to_h

      # make sure no survey data is lost
      raise 'Project as existing answers to questions. Aborting.' if project.results.count > 0

      # delete any existing answers or questions
      project.questions.each do |q|
        q.answers.destroy_all
      end
      project.questions.destroy_all

      # create new questions and answers
      answer_mapping = {}
      question_mapping = {}
      questions.each do |q_id, q|
        question = Question.new(project: project, question: q[:question])
        q[:answers].each_with_index do |a, idx|
          answer = Answer.new(answer: a[:answer], label: a[:label], color: a[:color])
          question.question_answers.build(answer: answer, order: idx)
        end
        question.save
        question_mapping[q[:id]] = question.id
        question.answers.each_with_index do |a, idx|
          answer_mapping[q[:answers][idx][:id].to_i] = a.id
        end
      end

      # delete any existing transitions
      project.transitions.destroy_all

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
        Transition.create(from_question_id: from_question,
                          to_question_id: question_mapping[t[:transition][:to_question].to_i],
                          answer_id: answer,
                          project: project)
      end
    end

    def destroy
    end

    private

    def question_sequence_params
      params.require(:question_sequence).permit(:questions => {}, :transitions => {})
    end

  end
end
