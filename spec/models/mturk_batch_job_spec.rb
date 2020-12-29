require 'rails_helper'

RSpec.describe MturkBatchJob, type: :model do
  it { is_expected.to validate_presence_of :title }
  it { is_expected.to validate_presence_of :description }

  it 'validates sandbox setting on qualification list' do
    batch_job = MturkBatchJob.new(sandbox: true, mturk_worker_qualification_list: MturkWorkerQualificationList.new(sandbox: false))
    batch_job.valid?
    expect(batch_job.errors[:base]).to include("The selected qualification list does not have the same settings for 'sandbox'. The records need to have the same sandbox setting.")
  end

  it 'validates qualification list contains qualification type id' do
    batch_job = MturkBatchJob.new(mturk_worker_qualification_list: MturkWorkerQualificationList.new)
    batch_job.valid?
    expect(batch_job.errors[:base]).to include("The selected qualification list does not contain a qualification type ID.")
  end

  it 'validates qualification list contains qualified workers' do
    batch_job = MturkBatchJob.new(mturk_worker_qualification_list: MturkWorkerQualificationList.new)
    batch_job.valid?
    expect(batch_job.errors[:base]).to include("The selected qualification list does not contain any qualified workers.")
  end
end
