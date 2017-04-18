require 'rails_helper'

RSpec.describe Result, type: :model do
  it {should belong_to(:user)}
  it {should belong_to(:question)}
  it {should belong_to(:answer)}
  it {should belong_to(:project)}
end
