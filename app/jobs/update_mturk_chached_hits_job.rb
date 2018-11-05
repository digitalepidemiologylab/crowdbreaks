class UpdateMturkChachedHitsJob < ApplicationJob
  queue_as :default

  after_enqueue do |job|
    MturkCachedHit.delete_all
  end

  def perform(user_id)
    sleep(10.seconds)
    # mturk = Mturk.new(sandbox: true)
    # all_hits = @mturk.list_all_hits
    # all_hits.each do |hit|
    #   MturkCachedHit.create(hit.to_h)
    # end
    ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'completed', job_type: 'update_mturk_hits')
  end
end
