class CrateQuestionSequenceLogsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :question_sequence_logs do |t|
      t.jsonb :log, null: false, default: '{}'
      t.timestamps
    end
    add_reference :results, :question_sequence_log, index: true, default: nil
  end
end
