class AddIndexToEventsApproved < ActiveRecord::Migration[8.1]
  def change
    add_index :events, :approved
  end
end
