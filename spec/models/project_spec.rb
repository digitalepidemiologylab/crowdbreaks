# == Schema Information
#
# Table name: projects
#
#  id                       :integer          not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  title_translations       :jsonb
#  description_translations :jsonb
#  es_index_name            :string
#

require 'rails_helper'

RSpec.describe Project, type: :model do
  it { is_expected.to validate_presence_of :title }
  it { is_expected.to validate_presence_of :description }
end
