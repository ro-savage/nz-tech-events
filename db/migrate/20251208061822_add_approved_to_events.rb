class AddApprovedToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :approved, :boolean, default: false, null: false

    # Approve all existing events
    reversible do |dir|
      dir.up do
        execute "UPDATE events SET approved = true"
      end
    end
  end
end
