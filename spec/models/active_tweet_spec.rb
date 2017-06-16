# == Schema Information
#
# Table name: active_tweets
#
#  id          :integer          not null, primary key
#  tweet_id    :integer
#  project_id  :integer
#  num_answers :integer          default(0)
#  uncertainty :float            default(1.0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe ActiveTweet, type: :model do
  it {should belong_to(:project)}
end
