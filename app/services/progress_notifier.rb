class ProgressNotifier
  def initialize(record_id, user_id, record_type, total_iterations)
    @record_type = record_type
    @record_id = record_id
    @user_id = user_id
    @prev_progress = 0
    @total_iterations = total_iterations
  end

  def update_progress(i)
    progress = (100*i/@total_iterations).ceil
    if @prev_progress < progress
      ActionCable.server.broadcast("job_notification:#{@user_id}", record_id: @record_id, record_type: @record_type, job_type: "progress", progress: progress)
      @prev_progress = progress
    end
  end

  def finish
    progress = 100
    ActionCable.server.broadcast("job_notification:#{@user_id}", record_id: @record_id, record_type: @record_type, job_type: "progress", progress: progress)
    @prev_progress = progress
  end
end
