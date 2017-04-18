require 'rails_helper'

RSpec.describe Transition, type: :model do
  it {should belong_to(:answer)}
  it {should belong_to(:project)}
  it {should belong_to(:from_question).class_name('Question')}
  it {should belong_to(:to_question).class_name('Question')}
end
