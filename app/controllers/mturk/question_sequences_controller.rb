class Mturk::QuestionSequencesController < ApplicationController
  after_action :allow_cross_origin, only: [:show]
  layout 'mturk'

  def show
    # retrieve task for hit id
    @hit_id = params[:hitId]
    task = get_task(@hit_id)
    if task.nil?
      head :bad_request
      return
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
      @tweet_id = get_tweet_id_for_worker(@worker_id, task)
      if @tweet_id.blank?
        # All work for worker has been done, exclude from qualification 
        Mturk.new(sandbox: @sandbox).exclude_worker_from_qualification(@worker_id, task.mturk_batch_job.qualification_type_id)
        @no_work_available = true # used for rendering information to the worker that he has finished all work
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
    results = tasks_params.fetch(:results, []) 
    logs = tasks_params.fetch(:logs, {}) 

    # try to store results even if task couldn't be found
    unless results.empty?
      if not create_results_for_task(results, task.try(:id), logs)
        head :bad_request
      end
    end

    if task.present?
      task.update_on_final(tasks_params)
    else
      Rails.logger.error("Task for #{tasks_params[:hit_id]} could not be found")
    end

    head :ok
  end

  def create
    # Store result
    result = Result.new(results_params)

    if result.task_id.nil?
      Rails.logger.error("Task for #{params[:hit_id]} could not be found")
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
      results_params = r[:result].merge({task_id: task_id, mturk_result: true, question_sequence_log_id: qs_log.id})
      result = Result.new(results_params)
      if not result.save
        return false
      end
    end
    true
  end

  def get_tweet_id_for_worker(worker_id, task)
    Rails.logger.debug "Assigning task for worker #{worker_id}..."
    w = MturkWorker.find_by(worker_id: worker_id)
    w = MturkWorker.create(worker_id: worker_id) if w.nil?
    w.assign_task(task)
    tweet_id = task.mturk_tweet.try(:tweet_id)
    if tweet_id.nil?
      Rails.logger.info "No tweet ID could be set"
    else
      Rails.logger.info "Tweet found successfully to be #{tweet_id}"
    end
 
    return tweet_id.to_s
  end

  def tasks_params
    params.require(:task).permit(:hit_id, :tweet_id, :worker_id, :assignment_id,
                                 results: [result: [:answer_id, :question_id, :tweet_id, :user_id, :project_id]],
                                 logs: [:timeInitialized, :answerDelay, :timeMounted, :userTimeInitialized, :totalDurationQuestionSequence, :timeQuestionSequenceEnd, :totalDurationUntilMturkSubmit, :timeMturkSubmit,
                                        results: [:submitTime, :timeSinceLastAnswer, :questionId],
                                        resets: [:resetTime, :resetAtQuestionId, previousResultLog: [:submitTime, :timeSinceLastAnswer, :questionId]]])
  end

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id, :user_id, :project_id).merge(task_id: get_task(params[:hit_id]).try(:id), mturk_result: true)
  end

  def get_task(hit_id)
    return nil unless hit_id.present?
    Task.find_by(hit_id: hit_id)
  end

  def allow_cross_origin
    response.headers.delete "X-Frame-Options"
  end
end
