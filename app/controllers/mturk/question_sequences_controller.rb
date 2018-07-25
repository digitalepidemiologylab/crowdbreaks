class Mturk::QuestionSequencesController < ApplicationController
  after_action :allow_cross_origin, only: [:show]
  layout 'mturk'

  def show
    # retrieve task for hit id
    @hit_id = params['hitId']
    task = get_task(@hit_id)
    unless task.present?
      head :bad_request
      return
    end

    @project = task.mturk_batch_job.project
    @sandbox = task.mturk_batch_job.sandbox

    # Mturk info
    @assignment_id = params['assignmentId']
    @preview_mode = ((@assignment_id == "ASSIGNMENT_ID_NOT_AVAILABLE") or (not @assignment_id.present?))

    # Collect question sequence info
    @question_sequence = QuestionSequence.new(@project).create
    
    @tweet_id = task.tweet_id
    
    # other
    @translations = I18n.backend.send(:translations)[:en][:question_sequences]
  end

  def final
    # fetch associated task
    task = get_task(tasks_params[:hit_id])
    results = tasks_params.fetch(:results, []) 

    unless results.empty?
      if not create_results_for_task(results, task.try(:id))
        head :bad_request
      end
    end

    if task.present?
      task.update_attributes(assignment_id: tasks_params[:assignment_id],
                             worker_id: tasks_params[:worker_id],
                             time_completed: Time.now,
                             lifecycle_status: :reviewable)
    else
      Rails.logger.error("Task for #{tasks_params[:hit_id]} could not be found")
    end

    head :ok
  end

  def create
    authorize! :create, Result
    # Store result
    p results_params
    result = Result.new(results_params)
    if result.save
      head :ok, content_type: "text/html"
    else
      head :bad_request
    end
  end


  private

  def create_results_for_task(results, task_id)
    results.each do |r|
      results_params = r[:result].merge({task_id: task_id, mturk_result: true})
      result = Result.new(results_params)
      if not result.save
        return false
      end
    end
    true
  end

  def tasks_params
    params.require(:task).permit(:hit_id, :tweet_id, :worker_id, :assignment_id, results: [result: [:answer_id, :question_id, :tweet_id, :user_id, :project_id]])
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
