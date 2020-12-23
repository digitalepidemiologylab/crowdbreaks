class CreateMturkWorkerQualificationListJob < ApplicationJob
  queue_as :default

  after_perform do |job|
    qual_list = MturkWorkerQualificationList.find_by(id: job.arguments.first)
    qual_list.default_status! if qual_list.present?
  end

  def perform(qual_id, worker_rows, destroy_first: false)
    qual_list = MturkWorkerQualificationList.find_by(id: qual_id)
    return unless qual_list.present?

    if destroy_first
      qual_list.qualified_workers.delete_all
    end

    if worker_rows.count > 0
      worker_list = []
      worker_rows.each do |row|
        worker = MturkWorker.find_by(worker_id: row[0])
        if not worker.present?
          worker = MturkWorker.create(worker_id: row[0])
        end
        worker_list.push(worker)
      end
      qual_list.update_attribute(:mturk_workers, worker_list)
    end
  end
end
