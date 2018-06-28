class AnswerSerializer < ActiveModel::Serializer
  # attributes :id, :key, :answer, :color
  attributes :id, :answer, :color
  belongs_to :question
end
