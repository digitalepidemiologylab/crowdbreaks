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
    expect(project.errors[:accessible_by_email_pattern]).to include(
      I18n.t('activerecord.errors.models.project.attributes.accessible_by_email_pattern.invalid')
    )

    project.accessible_by_email_pattern = ['valid@email*']
    project.valid?
    expect(project.errors[:accessible_by_email_pattern]).not_to include(
      I18n.t('activerecord.errors.models.project.attributes.accessible_by_email_pattern.invalid')
    )
  end

  it 'validates storage mode & auto MTurking compatibility' do
    project = Project.new
    project.auto_mturking = true
    project.storage_mode = 's3'
    project.valid?
    expect(project.errors[:storage_mode]).to include(
      I18n.t('activerecord.errors.models.project.attributes.storage_mode.choose_es_mode')
    )

    project.storage_mode = 's3-es'
    project.valid?
    expect(project.errors[:storage_mode]).not_to include(
      I18n.t('activerecord.errors.models.project.attributes.storage_mode.choose_es_mode')
    )
  end

  it 'validates tweets per batch & auto MTurking compatibility' do
    project = Project.new
    project.auto_mturking = true
    project.tweets_per_batch = nil
    project.valid?
    expect(project.errors[:tweets_per_batch]).to include(
      I18n.t('activerecord.errors.models.project.attributes.tweets_per_batch.cannot_be_blank')
    )

    project.tweets_per_batch = 2000
    project.valid?
    expect(project.errors[:tweets_per_batch]).not_to include(
      I18n.t('activerecord.errors.models.project.attributes.tweets_per_batch.cannot_be_blank')
    )

    project.auto_mturking = false
    project.tweets_per_batch = 2000
    project.valid?
    expect(project.errors[:tweets_per_batch]).to include(
      I18n.t('activerecord.errors.models.project.attributes.tweets_per_batch.must_be_blank')
    )

    project.tweets_per_batch = nil
    project.valid?
    expect(project.errors[:tweets_per_batch]).not_to include(
      I18n.t('activerecord.errors.models.project.attributes.tweets_per_batch.must_be_blank')
    )
  end
end
