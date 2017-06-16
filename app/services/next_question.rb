class NextQuestion
  attr_reader :params

  def initialize(params)
    @params = params
    puts "params"
    p @params
  end

  def next_question
    possible_transitions = find_possible_transitions
    case possible_transitions.size
    when 0
      # End question sequence
      return nil
    when 1
      possible_answer = possible_transitions.first.answer_id
      if !possible_answer.nil? && possible_answer != params[:answer_id].to_i
        # Answer given is not valid for transition, stop question sequence
        return nil
      end
      return possible_transitions.first.to_question
    else
      # case multiple possibilities, find the right transition based on the given answer
      transitions = possible_transitions.where(answer_id: params[:answer_id])
      if transitions.size == 1
        return transitions.first.to_question
      elsif transitions.empty?
        # End question sequence
        return nil
      else
        raise Exception, 'Multiple transitions defined for given answer!'
      end
    end
  end

  def find_possible_transitions
    Transition.where(project_id: params[:project_id], from_question: params[:question_id])
  end

end
