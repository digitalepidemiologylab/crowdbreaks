# RailsSettings Model
class Setting < RailsSettings::Base
  # cache_prefix { "v1" }

  scope :mturk_auto do
    field :new_batch_each, type: :integer, validates: { inclusion: { in: [nil, *(1..12)] } }
    field :sampled_status, type: :array, default: %w[]
    field :max_tasks_per_worker, type: :integer, validates: { numericality: { only_integer: true } }, default: 1000
  end
end
