# == Schema Information
#
# Table name: answer_sets
#
#  id         :integer          not null, primary key
#  name       :string
#  answer0_id :integer
#  answer1_id :integer
#  answer2_id :integer
#  answer3_id :integer
#  answer4_id :integer
#  answer5_id :integer
#  answer6_id :integer
#  answer7_id :integer
#  answer8_id :integer
#  answer9_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe AnswerSet, type: :model do
  it {should belong_to(:answer0).class_name('Answer')}
  it {should belong_to(:answer1).class_name('Answer')}
  it {should belong_to(:answer2).class_name('Answer')}
  it {should belong_to(:answer3).class_name('Answer')}
  it {should belong_to(:answer4).class_name('Answer')}
  it {should belong_to(:answer5).class_name('Answer')}
  it {should belong_to(:answer6).class_name('Answer')}
  it {should belong_to(:answer7).class_name('Answer')}
  it {should belong_to(:answer8).class_name('Answer')}
  it {should belong_to(:answer9).class_name('Answer')}
end
