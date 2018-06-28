class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :question
  has_many :answers
end
