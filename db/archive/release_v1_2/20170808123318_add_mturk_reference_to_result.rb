class AddMturkReferenceToResult < ActiveRecord::Migration[5.0]
  def change
    add_reference :results, :mturk_token, index: true, default: nil
  end
end
