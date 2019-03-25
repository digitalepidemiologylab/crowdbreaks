class AnswerSerializer < ActiveModel::Serializer
  attributes :id, :answer, :color, :label, :tag
  belongs_to :question
end
