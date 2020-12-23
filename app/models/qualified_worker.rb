class QualifiedWorker < ApplicationRecord
  belongs_to :mturk_worker
  belongs_to :mturk_worker_qualification_list
end
