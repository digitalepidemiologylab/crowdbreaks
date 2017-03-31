class ResultsController < ApplicationController
  def new
    @result = Result.new
    @question = Question.find_by(id: params[:question_id])
    valid_answers = @question.answer_set.get_valid_answers
    @answers = Answer.where(id: valid_answers)
  end

  def create
    # Find next question 
    next_question = get_next_question(results_params)

    @result = Result.new(results_params)
    if @result.save
      if next_question.nil?
        # End of question sequence
        redirect_to projects_path
        flash[:notice] = "Question sequence successfully completed!"
      else
        # Go to next question
        respond_to do |format|
          format.html { redirect_to new_question_result_path(next_question) }
        end
      end
    else
      redirect_to projects_path
      flash[:alert] = "An error has occurred"
    end
  end


  private

  def get_next_question(rp)
    possible_transitions = Transition.where(project_id: rp[:project_id], from_question: rp[:question_id])
    if possible_transitions.size == 0
      # End question sequence
      return nil
    elsif possible_transitions.size == 1
      possible_answer = possible_transitions.first.answer_id
      if !possible_answer.nil? and possible_answer != rp[:answer_id]
        # Answer given is not valid for transition, stop question sequence
        return nil
      end
      return possible_transitions.first.to_question
    else
      # case multiple possibilities, find the right transition based on the given answer
      transitions = possible_transitions.where(answer_id: rp[:answer_id])
      if transitions.size == 1
        return transitions.first.to_question
      elsif transitions.size == 0
        # End question sequence
        return nil
      else
        raise Exception.new('Multiple transitions defined for given answer!')
      end
    end
  end

  def results_params
    params.require(:result).permit(:answer_id).merge({user_id: get_user_id, question_id: params[:question_id], project_id: get_current_project})
  end

  def get_user_id
    if current_user
      return current_user.id 
    else
      return nil
    end
  end

  def get_current_project
    return Question.find_by(id: params[:question_id]).project_id
  end
end
