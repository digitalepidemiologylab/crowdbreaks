require 'rails_helper'

RSpec.describe ActiveTweet, type: :model do
  it {should belong_to(:project)}
end
