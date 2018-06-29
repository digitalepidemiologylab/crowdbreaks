class AnswerSerializer < ActiveModel::Serializer
  attributes :id, :answer, :color, :label
  belongs_to :question
end
