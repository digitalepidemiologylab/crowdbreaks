require 'rails_helper'

RSpec.describe CreatePublicTweetsJob, type: :job do
  let!(:project) { FactoryBot.create(:project) }
  let!(:user) { FactoryBot.create(:user) }

  describe "#perform_later" do
    it "enqueues a job" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        CreatePublicTweetsJob.perform_later(project.id, user.id, [1,2,3], destroy_first: true)
      }.to have_enqueued_job
    end
  end
end
