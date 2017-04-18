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
