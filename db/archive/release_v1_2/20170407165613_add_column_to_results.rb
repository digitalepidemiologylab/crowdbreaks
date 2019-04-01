class AddColumnToResults < ActiveRecord::Migration[5.0]
  def change
    add_reference :results, :tweet, index: true
  end
end
