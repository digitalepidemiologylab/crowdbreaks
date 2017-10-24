class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :question
  has_many :answers

  def question
    object.question_translations[instance_options[:locale]]
  end
end
