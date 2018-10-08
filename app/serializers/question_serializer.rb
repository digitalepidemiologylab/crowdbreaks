class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :question, :instructions
  has_many :answers

  def attributes(*args)
    hash = super
    hash[:is_editable] = is_editable if @instance_options[:edit_mode]
    hash
  end

  def is_editable
    object.results.count == 0
  end
end
