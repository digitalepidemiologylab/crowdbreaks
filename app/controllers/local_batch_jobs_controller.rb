class LocalBatchJobsController < ApplicationController
  def show
    @local_batch_job = LocalBatchJob.friendly.find(params[:id])
    # only allow certain users to do task
    if not user_signed_in? or not @local_batch_job.allows_user?(current_user&.id)
      raise CanCan::AccessDenied
    end

    @user_id = current_user.id
    @user_count = @local_batch_job.results.counts_by_user(@user_id)

    @total_count = @local_batch_job.local_tweets.is_available.count
    @total_count_unavailable = @local_batch_job.local_tweets.is_unavailable.count

    @tweet_id = @local_batch_job.local_tweets.not_assigned_to_user(@user_id, @local_batch_job.id).is_available.first&.tweet_id
    @no_work_available = @tweet_id.nil? ? true : false
    @tweet_is_available = TweetValidation.new.tweet_is_valid?(@tweet_id)
    if not @tweet_is_available
      LocalTweet.set_to_unavailable(@tweet_id, @local_batch_job.id)
    end

    @project = @local_batch_job.project
    @instructions = @local_batch_job.instructions
    @question_sequence = QuestionSequence.new(@project).create
    @translations = I18n.backend.send(:translations)[I18n.locale][:question_sequences]
  end

  def final
    user_id = final_params[:user_id]
    if user_id.nil? or final_params[:tweet_id].nil?
      head :bad_request and return 
    end
    local_batch_job = LocalBatchJob.friendly.find(params[:local_batch_job_id])

    results = final_params.fetch(:results, []) 
    unless results.empty?
      if not create_results(results, local_batch_job.id)
        head :bad_request
      end
    end

    tweet_id = local_batch_job.
      local_tweets.
      not_assigned_to_user(user_id, local_batch_job.id).
      is_available&.
      first&.
      tweet_id&.
      to_s

    no_work_available = tweet_id.nil? ? true : false
    tweet_is_available = TweetValidation.new.tweet_is_valid?(tweet_id)
    if not tweet_is_available
      LocalTweet.set_to_unavailable(tweet_id.to_i, local_batch_job.id)
    end

    total_count = local_batch_job.local_tweets.is_available.count
    user_count = local_batch_job.results.counts_by_user(user_id)
    total_count_unavailable = local_batch_job.local_tweets.is_unavailable.count

    render json: {
      tweet_id: tweet_id,
      tweet_is_available: tweet_is_available,
      user_count: user_count,
      total_count: total_count,
      total_count_unavailable: total_count_unavailable,
      no_work_available: no_work_available
    }, status: 200
  end

  private

  def create_results(results, local_batch_job_id)
    results.each do |r|
      result_params = r[:result].merge({local_batch_job_id: local_batch_job_id})
      result = Result.new(result_params)
      return false if not result.save
    end
    true
  end

  def final_params
    params.require(:qs).permit(:tweet_id, :user_id, :project_id, results: [result: [:answer_id, :question_id, :tweet_id, :user_id, :project_id]])
  end
end

