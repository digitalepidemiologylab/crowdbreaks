class TransitionSerializer < ActiveModel::Serializer
  attributes :from_question, :transition

  def from_question
    object.from_question.nil? ? 'start' : object.from_question.id
  end
  
  def transition
    {
      'to_question': object.to_question.id,
      'answer': object.try(:answer).try(:id)
    }
  end
end
