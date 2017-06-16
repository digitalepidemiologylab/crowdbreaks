# == Schema Information
#
# Table name: answers
#
#  id                  :integer          not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  key                 :string
#  order               :integer          default(0)
#  answer_translations :jsonb
#

require 'rails_helper'

RSpec.describe Answer, type: :model do
  it { is_expected.to validate_presence_of :answer }
  it { is_expected.to validate_presence_of :key }
  it { is_expected.to validate_uniqueness_of(:key)  }
end
