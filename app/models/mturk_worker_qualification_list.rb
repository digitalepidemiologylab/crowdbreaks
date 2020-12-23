class MturkWorkerQualificationList < ApplicationRecord
  has_and_belongs_to_many :mturk_workers
end
