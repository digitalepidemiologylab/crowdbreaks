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

    # transitions
    transitions = Hash.new{|h, k| h[k] = []}
    transitions_serialized.each do |t|
      transitions[t[:from_question]] << t[:transition]
    end
    num_transitions = Transition.find_path_length(transitions)
    {
      'num_transitions': num_transitions,
      'transitions': transitions,
      'questions': questions
    }

  end
end
