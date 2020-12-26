class QualificationListValidator < ActiveModel::Validator
  def validate(record)
    if record.mturk_worker_qualification_list.present?
      if record.sandbox != record.mturk_worker_qualification_list.sandbox
        record.errors[:base] << "The selected qualification list does not have the same settings for 'sandbox'. The records need to have the same sandbox setting."
      end

      if record.mturk_worker_qualification_list.qualified_workers.count == 0
        record.errors[:base] << "The selected qualification list does not contain any qualified workers."
      end

      if not record.mturk_worker_qualification_list.qualification_type_id.present?
        record.errors[:base] << "The selected qualification list does not contain a qualification type ID."
      end
    end
  end
end
