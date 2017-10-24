class AnswerSerializer < ActiveModel::Serializer
  attributes :id, :key, :answer, :color
  belongs_to :question

  def answer
    object.answer_translations[instance_options[:locale]]
  end
end
