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
    transitions = get_transitions
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
      'questions': get_questions(edit_mode: true),
      'transitions': get_editable_transitions
    }
  end

  def update(questions, transitions)
    id_mapping = update_question_answers(questions)
    update_transitions(transitions, id_mapping)
  end

  def destroy
    # delete any existing answers or questions
    @project.questions.each do |q|
      # deletes answers and QuestionAnswers on join table
      Answer.where(id: q.answers.pluck(:id)).destroy_all
    end
    @project.questions.destroy_all
    # delete any existing transitions
    @project.transitions.destroy_all
  end


  private 

  def update_question_answers(questions)
    id_mapping = {questions: {}, answers: {}}
    previous_questions = @project.questions.pluck(:id)
    new_questions = []
    questions.each do |q_id, q|
      if q[:original_id].present?
        question = update_question(q)
      else
        question = create_question(q)
      end
      question_answers = []
      q[:answers].each_with_index do |a, idx|
        if a[:original_id].present?
          answer = update_answer(a)
        else
          answer = create_answer(a)
        end
        question_answers.push({answer: answer, order: idx})
        id_mapping[:answers][a[:id].to_i] = answer.id
      end
      new_answers = question_answers.pluck(:answer)&.pluck(:id)
      previous_answers = question.answers.pluck(:id)
      if not previous_answers == new_answers
        question.question_answers.delete_all
        question.question_answers.build(question_answers)
        unused_answers = previous_answers - new_answers
        if unused_answers.length > 0
          delete_answers(unused_answers)
        end
      end
      question.save
      new_questions.push(question.id)
      id_mapping[:questions][q[:id]] = question.id
    end
    unused_questions = previous_questions - new_questions
    delete_questions(unused_questions)
    return id_mapping
  end

  def update_transitions(transitions, id_mapping)
    previous_transitions = @project.transitions.pluck(:id)
    new_transitions = []
    transitions.to_a.each do |id, t|
      # map IDs to newly generated answers and questions
      from_question = nil
      if t[:from_question] != 'start'
        from_question = id_mapping[:questions][t[:from_question].to_i]
      end
      to_question = id_mapping[:questions][t[:transition][:to_question].to_i]
      answer = nil
      if t[:transition][:answer] != ""
        answer = id_mapping[:answers][t[:transition][:answer].to_i]
      end

      # Update or create transition
      transition_attributes = {from_question_id: from_question, to_question_id: to_question, answer_id: answer, project: @project}
      if t[:original_id].present?
        transition = update_transition(t, transition_attributes)
      else
        transition = create_transition(transition_attributes)
      end
      if not transition.persisted?
        raise 'An error occured when trying to update/create transition'
      end
      new_transitions.push(transition.id)
    end

    # delete unused transitions
    unused_transitions = previous_transitions - new_transitions
    if unused_transitions.length > 0
      Transition.where(id: unused_transitions).delete_all
    end
  end

  def update_transition(t, transition_attributes)
    transition = Transition.find(t[:original_id])
    transition.update_attributes(transition_attributes)
    return transition
  end

  def create_transition(transition_attributes)
    return Transition.create(transition_attributes)
  end

  def update_question(q)
    original_question = Question.find(q[:original_id])
    original_question.update_attributes({question: q[:question], instructions: q[:instructions], tag: q[:tag]})
    return original_question
  end

  def create_question(q)
    return Question.new(project: @project, question: q[:question], instructions: q[:instructions], tag: q[:tag])
  end

  def delete_questions(ids)
    questions = Question.where(id: ids)
    questions.each do |q|
      raise 'Cannot delete question with associated results' if q.results.count > 0
      q.question_answers.delete_all
      q.destroy
    end
  end

  def delete_answers(ids)
    answers = Answer.where(id: ids)
    return if answers.empty?
    # ensure none of the answers have associated results
    if not answers.map{|a| a.results.count == 0 }.all?
      raise 'Cannot delete answers with associated results'
    end
    answers.delete_all
  end

  def update_answer(a)
    original_answer = Answer.find(a[:original_id])
    original_answer.update_attributes({answer: a[:answer], color: a[:color], label: a[:label], tag: a[:tag]})
    return original_answer
  end

  def create_answer(a)
    return Answer.create(answer: a[:answer], color: a[:color], label: a[:label], tag: a[:tag])
  end

  def get_questions(edit_mode: false)
    options = {locale: I18n.locale.to_s, edit_mode: edit_mode}
    questions_serialized = ActiveModelSerializers::SerializableResource.new(@project.questions, options).as_json
    questions = {}
    # collect possible answers for each question
    questions_serialized.each do |q|
      questions[q[:id]] = q
    end
    return questions
  end

  def get_transitions
    options = {locale: I18n.locale.to_s}
    transitions_serialized = ActiveModelSerializers::SerializableResource.new(@project.transitions, options).as_json
    transitions = Hash.new{|h, k| h[k] = []}
    transitions_serialized.each do |t|
      transitions[t[:from_question]] << t[:transition]
    end
    return transitions
  end

  def get_editable_transitions
    options = {locale: I18n.locale.to_s}
    transitions_serialized = ActiveModelSerializers::SerializableResource.new(@project.transitions, options).as_json
    transitions = {}
    transitions_serialized.each do |t|
      transitions[t[:id]] = {'id': t[:id], 'from_question': t[:from_question], 'transition': t[:transition]}
    end
    return transitions
  end
end
