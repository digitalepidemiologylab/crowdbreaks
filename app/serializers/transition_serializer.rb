class TransitionSerializer < ActiveModel::Serializer
  attributes :id, :from_question, :transition

  def from_question
    object.from_question.nil? ? 'start' : object.from_question.id
  end
  
  def transition
    {
      'to_question': object.try(:to_question).try(:id),
      'answer': object.try(:answer).try(:id)
    }
  end
end
