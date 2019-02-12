class Mturk::QuestionSequencesController < ApplicationController
  skip_before_action :verify_authenticity_token
  after_action :allow_cross_origin, only: [:show]
  layout 'mturk'

  def show
    # retrieve task for hit id
    @hit_id = params[:hitId]
    task = get_task(@hit_id)
    if task.nil?
      head :bad_request and return
    end
    # Mturk info
    @assignment_id = params[:assignmentId]
    @preview_mode = ((@assignment_id == "ASSIGNMENT_ID_NOT_AVAILABLE") or (not @assignment_id.present?))
    @worker_id = params[:workerId]
    @tweet_id = nil
    @no_work_available = false
    @mturk_batch_job = task.mturk_batch_job
    if not @preview_mode
      # worker has accepted the HIT
      @tweet_id, @tweet_text, @notification = get_tweet_for_worker(@worker_id, task)
    end
    # Collect question sequence info
    @project = @mturk_batch_job.project
    @question_sequence = QuestionSequence.new(@project).load
  end

  def final
    # Lock task table during creation of results and update of task
    lock_tables do
      # fetch associated task
      task = get_task(tasks_params[:hit_id])
      if task.nil?
        ErrorLogger.error("Task for #{tasks_params[:hit_id]} could not be found")
        head :bad_request and return
      end
      results = tasks_params.fetch(:results, []) 
      logs = tasks_params.fetch(:logs, {}) 
      # return if same HIT was already submitted before
      if task.results.count > 0
        Rails.logger.error("Worker #{tasks_params[:worker_id]} tried to submit work for task #{task.id}. " \
                           "For this task worker #{task.mturk_worker&.worker_id} has already submitted work.")
        head :bad_request and return
      end
      if results.present?
        begin
          create_results_for_task(results, task, logs)
        rescue
          head :bad_request and return
        else
          task.update_on_final(tasks_params)
        end
      else
        ErrorLogger.error("Submitted work for task #{task.id} contains no results")
        head :bad_request and return
      end
    end
    head :ok
  end

  def create
    # Store result
    result = Result.new(results_params)
    if result.task_id.nil?
      ErrorLogger.error("Task for #{params[:hit_id]} could not be found")
    end
    if result.save
      head :ok, content_type: "text/html"
    else
      head :bad_request
    end
  end


  private

  def create_results_for_task(results, task, logs)
    ActiveRecord::Base.transaction do  
      validate_results(results, task)
      qs_log = QuestionSequenceLog.create(log: logs)
      additional_params = {task_id: task.id, res_type: :mturk, question_sequence_log_id: qs_log.id}
      results.each do |r|
        result = r[:result].merge(additional_params)
        Result.create(result)
      end
    end
  end


  def validate_results(results, task)
    question_ids = []
    t_id_previous = nil
    results.each do |result|
      q_id = result[:result][:question_id]
      t_id = result[:result][:tweet_id]
      if t_id_previous.nil?
        t_id_previous = t_id
      else
        if t_id_previous != t_id
          ErrorLogger.error "Result validation failed. Tweet IDs are not consistent within results."
          raise "Results of task #{task.id} contain different tweet IDs (#{t_id_previous} vs. #{t_id})"
        end
      end
      # make sure questions are unique
      if not question_ids.include?(q_id)
        question_ids.push(q_id)
      else
        ErrorLogger.error "Result validation failed (question IDs are not unique)."
        raise "Results committed for task #{task.id} contain the same question multiple times."
      end
    end
    if not t_id_previous.nil?
      if t_id_previous != tasks_params[:tweet_id]
        ErrorLogger.error "Result validation failed. Tweet IDs are not consistent."
        raise "Result validation failed. Task #{task.id} contains different tweet IDs."
      end
    end
  end

  def get_tweet_for_worker(worker_id, task)
    ##
    # Returns tweet_id (str), tweet_text (str) pair for a specific worker-task pair. If no available task for the worker can be found it returns empty strings.
    Rails.logger.debug "Assigning task for worker #{worker_id}..."
    worker = MturkWorker.find_or_create_by(worker_id: worker_id)
    # Lock Task table
    lock_result = lock_tables do
      task.reload
      worker.reload
      # find a new tweet for worker and assign it through the task
      worker.assign_task(task)
    end
    if lock_result.lock_was_acquired?
      mturk_tweet, notification = lock_result.result
      return mturk_tweet&.tweet_id.to_s, mturk_tweet&.tweet_text.to_s, notification
    else
      ErrorLogger.error "Something went wrong when trying to acquire lock for task #{task.id}"
      return "", "", MturkNotification.new.error
    end
  end

  def lock_tables(options: {timeout_seconds: 10, transaction: true})
    # slightly paranoid locking of all tables involved
    Task.with_advisory_lock_result('mturk-task', options) do
      MturkTweet.with_advisory_lock('mturk-tweet', options) do
        Result.with_advisory_lock('mturk-result', options) do
          MturkWorker.with_advisory_lock('mturk-worker', options) do
            yield
          end
        end
      end
    end
  end

  def tasks_params
    params.require(:task).permit(:hit_id, :tweet_id, :worker_id, :assignment_id,
                                 results: [result: [:answer_id, :question_id, :tweet_id, :user_id, :project_id]],
                                 logs: [:timeInitialized, :delayStart, :delayNextQuestion, :timeMounted, :userTimeInitialized, :totalDurationQuestionSequence, :timeQuestionSequenceEnd, :totalDurationUntilMturkSubmit, :timeMturkSubmit,
                                        results: [:submitTime, :timeSinceLastAnswer, :questionId],
                                        resets: [:resetTime, :resetAtQuestionId, previousResultLog: [:submitTime, :timeSinceLastAnswer, :questionId]]])
  end

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id, :user_id, :project_id).merge(task_id: get_task(params[:hit_id]).try(:id), res_type: :mturk)
  end

  def get_task(hit_id)
    return nil unless hit_id.present?
    Task.find_by(hit_id: hit_id)
  end

  def allow_cross_origin
    response.headers.delete "X-Frame-Options"
  end
end
