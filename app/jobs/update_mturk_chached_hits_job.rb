class UpdateMturkChachedHitsJob < ApplicationJob
  queue_as :default

  after_enqueue do |job|
    MturkCachedHit.delete_all
  end

  def perform(*args)
    mturk = Mturk.new(sandbox: true)
    all_hits = @mturk.list_all_hits
    all_hits.each do |hit|
      MturkCachedHit.create(hit.to_h)
    end
  end
end
