class AddDescriptionMarkdownToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :description_markdown, :text
  end
end
