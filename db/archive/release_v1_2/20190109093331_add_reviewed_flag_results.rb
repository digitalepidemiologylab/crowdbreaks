class AddReviewedFlagResults < ActiveRecord::Migration[5.2]
  def change
    add_column :results, :manual_review_status, :integer, default: 0, null: false
  end
end
