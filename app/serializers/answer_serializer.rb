class AnswerSerializer < ActiveModel::Serializer
  attributes :id, :key, :answer, :color
  belongs_to :question
end
