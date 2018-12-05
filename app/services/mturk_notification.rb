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

  def max_tasks_by_worker_reached
    @notification = {
      status_code: :unsuccessful,
      code: 'max_tasks_by_worker_reached',
      title_message: 'You have completed all work in this HIT group.',
      message: 'This HIT (and future HITs in this group), cannot be completed since you have reached the maximum number of HITs which we allocate for a single worker. We kindly ask you to return the HIT and thank you for your understanding. You will be disqualified from this batch - however, you are very welcome to submit work in a later batch!',
    }
  end

  def all_tasks_finished
    @notification = {
      status_code: :unsuccessful,
      code: 'all_tasks_finished',
      title_message: 'All work in this batch has been completed.',
      message: 'No work could be retrieved because you have completed all work in this batch. We kindly ask you to return the HIT. You will be disqualified from this batch only - you are very welcome to submit work in a later batch!',
    }
  end

  def success?
    return false if @notification.empty?
    @notification[:status_code] == :success
  end
end
