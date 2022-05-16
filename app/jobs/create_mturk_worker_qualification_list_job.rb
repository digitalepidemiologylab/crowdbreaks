class CreateMturkWorkerQualificationListJob < ApplicationJob
  queue_as :default

  after_perform do |job|
    qual_list = MturkWorkerQualificationList.find_by(id: job.arguments.first)
    qual_list.default_status! if qual_list.present?
  end

  def perform(qual_id, worker_rows, destroy_first: false)
    qual_list = MturkWorkerQualificationList.find_by(id: qual_id)
    return unless qual_list.present? && worker_rows.count.positive?

    qual_list.qualified_workers.delete_all if destroy_first

    # Create qualification type
    unless qual_list.qualification_type_id.present?
      qual_type_id = qual_list.create_qualification_type
      qual_list.failed_status! and return if qual_type_id.nil?
    end

    worker_list = []
    mturk = Mturk.new(sandbox: qual_list.sandbox)
    worker_rows.each do |row|
      worker_id = row[0]
      # Find or create an MTurk worker
      worker = MturkWorker.find_or_create_by(worker_id: worker_id)
      worker_list << worker
      # Associate a worker with a qualification type
      mturk.add_worker_to_qualification(worker_id, qual_list.qualification_type_id)
    end
    qual_list.update_attribute(:mturk_workers, worker_list)
  end
end
