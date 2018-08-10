class LocalBatchJobsController < ApplicationController
  def show
    @local_batch_job = LocalBatchJob.friendly.find(params[:id])
    # only allow certain users to do task
    if not user_signed_in? or not @local_batch_job.allows_user?(current_user&.id)
      raise CanCan::AccessDenied
    end

    @user_id = current_user.id
    @user_count = @local_batch_job.assigned_to_user(@user_id).distinct.count(:tweet_id)

    @total_count = @local_batch_job.local_tweets.count

    @tweet_id = @local_batch_job.local_tweets.not_assigned_to_user(@user_id, @local_batch_job.id).first&.tweet_id
    @no_work_available = @tweet_id.nil? ? true : false

    @project = @local_batch_job.project
    @instructions = @local_batch_job.instructions
    @question_sequence = QuestionSequence.new(@project).create
    @translations = I18n.backend.send(:translations)[I18n.locale][:question_sequences]
  end

  def final
    p final_params
    if final_params[:user_id].nil? or final_params[:tweet_id].nil?
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
      not_assigned_to_user(final_params[:user_id], local_batch_job.id).
      first&.
      tweet_id

    render json: {
      tweet_id: tweet_id.to_s,
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

