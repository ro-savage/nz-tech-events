class AddSourceFieldsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :source, :string
    add_column :events, :source_url, :string
  end
end
