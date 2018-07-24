class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :question, :instructions
  has_many :answers
end
