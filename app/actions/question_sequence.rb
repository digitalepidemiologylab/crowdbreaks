class QuestionSequence
  def initialize(project)
    @project = project
  end

  def create
    # collect JSON data
    options = {locale: I18n.locale.to_s}
    questions_serialized = ActiveModelSerializers::SerializableResource.new(@project.questions, options).as_json
    transitions_serialized = ActiveModelSerializers::SerializableResource.new(@project.transitions, options).as_json

    # questions
    questions = {}
    # collect possible answers for each question
    questions_serialized.each do |q|
      questions[q[:id]] = {'id': q[:id], 'question': q[:question], 'answers': q[:answers]}
    end
    # find starting question
    initial_question_id = @project.initial_question.id

    # transitions
    transitions = Hash.new{|h, k| h[k] = []}
    transitions_serialized.each do |t|
      transitions[t[:from_question]] << t[:transition]
    end
    num_transitions = Transition.find_path_length(transitions)
    
    return {
      'questions': questions,
      'initial_question_id': initial_question_id,
      'num_transitions': num_transitions,
      'transitions': transitions
    }
  end

  def edit
    questions_serialized = ActiveModelSerializers::SerializableResource.new(@project.questions).as_json
    transitions_serialized = ActiveModelSerializers::SerializableResource.new(@project.transitions).as_json
    questions = {}
    # collect possible answers for each question
    questions_serialized.each do |q|
      questions[q[:id]] = {'id': q[:id], 'question': q[:question], 'answers': q[:answers]}
    end
    # transitions
    transitions = {}
    transitions_serialized.each do |t|
      transitions[t[:id]] = {'id': t[:id], 'from_question': t[:from_question], 'transition': t[:transition]}
    end
    
    return {
      'questions': questions,
      'transitions': transitions
    }
  end
end
