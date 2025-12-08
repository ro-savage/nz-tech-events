class AddApprovedOrganiserToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :approved_organiser, :boolean, default: false, null: false
    
    # Make all existing users approved organisers
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET approved_organiser = true"
      end
    end
  end
end
