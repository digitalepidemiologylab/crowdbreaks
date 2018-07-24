# == Schema Information
#
# Table name: questions
#
#  id                    :integer          not null, primary key
#  project_id            :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  answer_set_id         :integer
#  question_translations :jsonb
#  meta_field            :string
#

require 'rails_helper'

RSpec.describe Question, type: :model do
  it {should belong_to(:project)}
end
