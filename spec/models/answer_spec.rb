require 'rails_helper'

RSpec.describe Answer, type: :model do
  it { is_expected.to validate_presence_of :answer }
  it { is_expected.to validate_presence_of :key }
  it { is_expected.to validate_uniqueness_of(:key)  }
end
