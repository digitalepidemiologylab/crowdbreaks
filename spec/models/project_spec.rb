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

  it 'validates accessible_by_email_pattern' do
    project = Project.new
    project.accessible_by_email_pattern = ['invalid_email']
    project.valid?
    expect(project.errors[:accessible_by_email_pattern]).to include('Patterns need to be email patterns including "@"')

    project.accessible_by_email_pattern = ['valid@email*']
    project.valid?
    expect(project.errors[:accessible_by_email_pattern]).not_to include('Patterns need to be email patterns including "@"')
  end
end
