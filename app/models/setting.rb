# RailsSettings Model
class Setting < RailsSettings::Base
  # cache_prefix { "v1" }

  scope :mturk_auto do
    field :new_batch_each, type: :integer, validates: { inclusion: { in: [nil, *(1..12)] } }
    field :sampled_status, type: :array, default: %w[]
  end
end
