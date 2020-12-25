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

    # create qualification type
    unless qual_list.qualification_type_id.present?
      qual_type_id = qual_list.create_qualification_type
      if qual_type_id.nil?
        qual_list.failed_status! and return
      end
    end

    worker_list = []
    mturk = Mturk.new(sandbox: qual_list.sandbox)
    worker_rows.each do |row|
      worker_id = row[0]
      # find or create mturk worker
      worker = MturkWorker.find_or_create_by(worker_id: worker_id)
      worker_list.push(worker)
      # associate worker with qualification type
      mturk.add_worker_to_qualification(worker_id, qual_list.qualification_type_id)
    end
    qual_list.update_attribute(:mturk_workers, worker_list)
  end
end
