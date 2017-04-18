require 'rails_helper'

RSpec.describe Question, type: :model do
  it {should belong_to(:answer_set)}
  it {should belong_to(:project)}
end
