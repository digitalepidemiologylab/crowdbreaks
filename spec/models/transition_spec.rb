# == Schema Information
#
# Table name: transitions
#
#  id                     :integer          not null, primary key
#  from_question_id       :integer
#  answer_id              :integer
#  to_question_id         :integer
#  project_id             :integer
#  transition_probability :float
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require 'rails_helper'

RSpec.describe Transition, type: :model do
  it {should belong_to(:answer)}
  it {should belong_to(:project)}
  it {should belong_to(:from_question).class_name('Question')}
  it {should belong_to(:to_question).class_name('Question')}
end
