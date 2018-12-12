class Mturk::QuestionSequencesController < ApplicationController
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
    @sandbox = task.mturk_batch_job.sandbox

    if not @preview_mode
      # worker has accepted the HIT
      task.with_lock do
        @tweet_id, @tweet_text, @notification = get_tweet_for_worker(@worker_id, task)
      end
    end
    # Collect question sequence info
    @project = task.mturk_batch_job.project
    @mturk_instructions = task.mturk_batch_job.instructions
    @question_sequence = QuestionSequence.new(@project).load
  end

  def final
    # fetch associated task
    task = get_task(tasks_params[:hit_id])
    if task.nil?
      ErrorLogger.error("Task for #{tasks_params[:hit_id]} could not be found")
      head :bad_request and return
    end

    task.with_lock do
      results = tasks_params.fetch(:results, []) 
      logs = tasks_params.fetch(:logs, {}) 
      # return if same HIT was already submitted before
      if task.results.count > 0
        ErrorLogger.error("Mturk hit was already submitted before")
        head :ok and return
      end
      if results.present?
        if not create_results_for_task(results, task.id, logs)
          head :bad_request and return
        end
      else
        ErrorLogger.error("Submitted Mturk task contains no results")
      end
      task.update_on_final(tasks_params)
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

  def create_results_for_task(results, task_id, logs)
    qs_log = QuestionSequenceLog.create(log: logs)
    results.each do |r|
      results_params = r[:result].merge({task_id: task_id, res_type: :mturk, question_sequence_log_id: qs_log.id})
      result = Result.new(results_params)
      if not result.save
        return false
      end
    end
    true
  end

  def get_tweet_for_worker(worker_id, task)
    ##
    # Returns tweet_id (str), tweet_text (str) pair for a specific worker-task pair. If no available task for the worker can be found it returns empty strings.
    Rails.logger.debug "Assigning task for worker #{worker_id}..."
    worker = MturkWorker.find_or_create_by(worker_id: worker_id)
    # find a new tweet for worker and assign it through the task
    mturk_tweet, notification = worker.assign_task(task)
    return mturk_tweet&.tweet_id.to_s, mturk_tweet&.tweet_text.to_s, notification
  end

  def tasks_params
    params.require(:task).permit(:hit_id, :tweet_id, :worker_id, :assignment_id,
                                 results: [result: [:answer_id, :question_id, :tweet_id, :user_id, :project_id]],
                                 logs: [:timeInitialized, :answerDelay, :timeMounted, :userTimeInitialized, :totalDurationQuestionSequence, :timeQuestionSequenceEnd, :totalDurationUntilMturkSubmit, :timeMturkSubmit,
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
