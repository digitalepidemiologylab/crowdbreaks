# == Schema Information
#
# Table name: results
#
#  id          :integer          not null, primary key
#  question_id :integer
#  answer_id   :integer
#  user_id     :integer
#  project_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  tweet_id    :integer
#

require 'rails_helper'

RSpec.describe Result, type: :model do
  it {should belong_to(:user)}
  it {should belong_to(:question)}
  it {should belong_to(:answer)}
  it {should belong_to(:project)}
end
