class CreateCachedHitsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :mturk_cached_hits do |t|
      t.string :hit_id
      t.string :hit_type_id
      t.string :hit_group_id
      t.string :hit_layout_id
      t.text :title
      t.text :description
      t.text :question
      t.text :keywords
      t.string :requester_annotation
      t.string :hit_status
      t.string :hit_review_status
      t.integer :max_assignments
      t.integer :number_of_assignments_pending
      t.integer :number_of_assignments_available
      t.integer :number_of_assignments_completed
      t.decimal :reward, precision: 8, scale: 2
      t.integer :auto_approval_delay_in_seconds
      t.integer :assignment_duration_in_seconds
      t.jsonb :qualification_requirements
      t.datetime :creation_time
      t.datetime :expiration
      t.boolean :sandbox, default: true, null: false
      t.timestamps
    end
  end
end
