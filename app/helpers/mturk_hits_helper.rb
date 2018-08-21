module MturkHitsHelper
  def find_batch_job(hit_type_id)
    batch_job = MturkBatchJob.find_by(hittype_id: hit_type_id)
    if batch_job.nil?
      return hit_type_id
    else
      return link_to batch_job.name, mturk_batch_job_path(batch_job.id, come_from: 'mturk_hits')
    end
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

  def batch_job_exists_for_hit?(hittype_id)
    MturkBatchJob.exists?(hittype_id: hittype_id)
  end
end
