module Manage
  class LocalTweetsController < BaseController
    load_and_authorize_resource :local_batch_job, find_by: :slug, id_param: :manage_local_batch_job_id
    load_and_authorize_resource :local_tweet, through: :local_batch_job

    def index
      @local_tweets = @local_tweets.page params[:page]
    end
  end
end
