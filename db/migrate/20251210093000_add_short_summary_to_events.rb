class AddShortSummaryToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :short_summary, :text
  end
end
