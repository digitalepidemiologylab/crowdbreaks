namespace :mturk_cached_hits do
  desc "Clean Mturk cached hits"
  task destroy: :environment do
    MturkCachedHit.destroy_all
  end
end
