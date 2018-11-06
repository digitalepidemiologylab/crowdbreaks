class UpdateMturkChachedHitsJob < ApplicationJob
  queue_as :default

  def perform(user_id, sandbox)
    # check if same job is already running
    options = sandbox ? '_sandbox' : ''
    cache_key = "update_mturk_cached_hits#{options}_running"
    if Rails.cache.exist?(cache_key)
      # Another background job is already running, exit
      ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'failed', job_type: 'update_mturk_hits')
      return
    end

    # lock
    Rails.cache.write(cache_key, 1, expires_in: 1.hour)

    # Delete previous hits
    MturkCachedHit.where(sandbox: sandbox).delete_all

    # Load new hits
    mturk = Mturk.new(sandbox: sandbox)
    next_token = nil
    total = 0
    max_hits = 1000
    loop do
      all_hits = []
      resp = mturk.list_hits(next_token: next_token, max_results: 100)
      all_hits.push(*resp.hits)
      total += all_hits.length
      ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'running', job_type: 'update_mturk_hits', hits_loaded: total)
      all_hits.each do |hit|
        MturkCachedHit.create(hit.to_h.merge(sandbox: sandbox))
      end
      next_token = resp.next_token
      break if next_token.nil? or total >= max_hits
    end

    # Get rid of key again
    Rails.cache.delete(cache_key)
    if total >= max_hits
      message = 'Loaded maximum number of hits. Reloading...'
    else
      message = 'Successfully completed refresh. Reloading...'
    end
    ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'completed', job_type: 'update_mturk_hits', message: message)
  end
end
