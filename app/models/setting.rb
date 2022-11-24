# RailsSettings Model
class Setting < RailsSettings::Base
  # cache_prefix { "v1" }

  scope :mturk_auto do
    field :new_batch_each, type: :integer, validates: { inclusion: { in: [nil, *(1..12)] } }
    field :max_tasks_per_worker, type: :integer, validates: { numericality: { only_integer: true } }, default: 1000
    field :min_batch_completeness, type: :float, validates: { inclusion: 0.0..100.0 }, default: 98
  end
end
