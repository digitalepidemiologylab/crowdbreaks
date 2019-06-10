class MturkNotification
  def initialize
    @notification = {}
  end

  def success
    @notification = {
      status_code: :success,
      code: :success,
      title_message: '',
      message: '',
    }
  end

  def already_completed
    @notification = {
      status_code: :unsuccessful,
      code: 'already_completed',
      title_message: 'You have already completed this HIT.',
      message: 'You cannot work on this HIT again because you have previously submitted results for this HIT.',
    }
  end

  def max_tasks_by_worker_reached
    @notification = {
      status_code: :unsuccessful,
      code: 'max_tasks_by_worker_reached',
      title_message: 'You have completed all work in this HIT group.',
      message: 'This HIT (and future HITs in this group), cannot be completed since you have reached the maximum number of HITs which we allocate for a single worker. We kindly ask you to return the HIT and thank you for your work. You will be disqualified from this batch - however, you are very welcome to submit work in a later batch!',
    }
  end

  def all_tasks_finished
    @notification = {
      status_code: :unsuccessful,
      code: 'all_tasks_finished',
      title_message: 'All work in this batch has been completed.',
      message: 'No work could be retrieved because you have completed all work in this batch. We kindly ask you to return the HIT and thank you for your work. You are very welcome to submit work in a later batch!',
    }
  end

  def error
    @notification = {
      status_code: :error,
      code: 'error',
      title_message: 'Error',
      message: 'When trying to retrieve the task an error has occurred. We apologize and will try to fix this issue as soon as possible. Make sure not to accept many HITs at the same time.',
    }
  end

  def success?
    return false if @notification.empty?
    @notification[:status_code] == :success
  end
end
