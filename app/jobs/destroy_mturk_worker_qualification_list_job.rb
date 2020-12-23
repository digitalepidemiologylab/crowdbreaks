class DestroyMturkWorkerQualificationListJob < ApplicationJob
  queue_as :default

  def perform(qual_id)
    qual_list = MturkWorkerQualificationList.find_by(id: qual_id)
    qual_list.destroy if qual_list.present?
  end
end
