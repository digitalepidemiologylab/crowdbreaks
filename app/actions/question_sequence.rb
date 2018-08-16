class QuestionSequence
  def initialize(project)
    @project = project
  end

  def load
    # collect JSON data
    options = {locale: I18n.locale.to_s}

    # questions
    questions = get_questions
    initial_question_id = @project.initial_question.try(:id)

    # transitions
    transitions = get_transitions(mode: 'create')
    num_transitions = Transition.find_path_length(transitions)
    
    return {
      'questions': questions,
      'initial_question_id': initial_question_id,
      'num_transitions': num_transitions,
      'transitions': transitions
    }
  end

  def edit
    return {
      'questions': get_questions,
      'transitions': get_transitions(mode: 'edit')
    }
  end


  private 

  def get_questions
    options = {locale: I18n.locale.to_s}
    questions_serialized = ActiveModelSerializers::SerializableResource.new(@project.questions, options).as_json
    questions = {}
    # collect possible answers for each question
    questions_serialized.each do |q|
      questions[q[:id]] = {
        'id': q[:id],
        'question': q[:question],
        'answers': q[:answers],
        'instructions': q[:instructions]
      }
    end
    return questions
  end

  def get_transitions(mode: 'edit')
    options = {locale: I18n.locale.to_s}
    transitions_serialized = ActiveModelSerializers::SerializableResource.new(@project.transitions, options).as_json
    if mode == 'create'
      transitions = Hash.new{|h, k| h[k] = []}
      transitions_serialized.each do |t|
        transitions[t[:from_question]] << t[:transition]
      end
      return transitions
    elsif mode == 'edit'
      transitions = {}
      transitions_serialized.each do |t|
        transitions[t[:id]] = {'id': t[:id], 'from_question': t[:from_question], 'transition': t[:transition]}
      end
      return transitions
    end
  end
end
