class AddCounters < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :question_sequences_count, :integer, default: 0, null: false
    add_column :projects, :results_count, :integer, default: 0, null: false
    
    Project.find_each { |p| Project.reset_counters(p.id, :results)}
  end
end
