class AnswerSerializer < ActiveModel::Serializer
  attributes :id, :answer, :color, :label, :tag, :answer_type
  belongs_to :question
end
