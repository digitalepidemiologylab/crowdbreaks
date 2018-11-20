module MturkHitsHelper
  def find_batch_job(hit_id, come_from: 'mturk_hits')
    mturk_batch_job = Task.find_by(hit_id: hit_id)&.mturk_batch_job
    return link_to mturk_batch_job.name, mturk_batch_job_path(mturk_batch_job.id, come_from: come_from)
  end

  def find_task(hit_id)
    task = Task.find_by(hit_id: hit_id)
    if task.nil?
      return hit_id
    else
      return link_to 'Task '+task.id.to_s, mturk_batch_job_task_path(task.mturk_batch_job.id, task.id, come_from: 'mturk_hits')
    end
  end

  def task_exists_for_hit?(hit_id)
    Task.exists?(hit_id: hit_id)
  end

  def task_and_results_exist_for_hit?(hit_id)
    task = Task.find_by(hit_id: hit_id)
    return false if task.nil?
    return task.results.count > 0
  end

  def batch_job_exists_for_hit?(hit_id)
    mturk_batch_job = Task.find_by(hit_id: hit_id)&.mturk_batch_job
    mturk_batch_job.nil? ? false : true
  end
end
