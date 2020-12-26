class DestroyMturkWorkerQualificationListJob < ApplicationJob
  queue_as :default

  def perform(qual_id)
    qual_list = MturkWorkerQualificationList.find_by(id: qual_id)
    return unless qual_list.present?

    # Deleting qualification type will also delete associated hit types
    mturk = Mturk.new(sandbox: qual_list.sandbox)
    if qual_list.qualification_type_id.present?
      mturk.delete_qualification_type(qual_list.qualification_type_id)
    end

    # destroy
    qual_list.destroy if qual_list.present?
  end
end
