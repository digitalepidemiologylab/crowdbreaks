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

    return unless worker_rows.count > 0

    worker_list = []
    worker_rows.each do |row|
      worker = MturkWorker.find_or_create_by(worker_id: row[0])
      worker_list.push(worker)
    end
    qual_list.update_attribute(:mturk_workers, worker_list)

    # create qualification type
    unless qual_list.qualification_type_id.present?
      qual_type_id = qual_list.create_qualification_type
      if qual_type_id.nil?
        qual_list.failed_status! and return
      end
    end
  end
end
