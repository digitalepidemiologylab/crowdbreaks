class MturkCachedHit < ApplicationRecord
  def mturk_batch_job
    return nil if hit_id.nil?
    Task.find_by(hit_id: hit_id)&.mturk_batch_job
  end
end
