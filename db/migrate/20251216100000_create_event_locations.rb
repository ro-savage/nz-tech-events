class CreateEventLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :event_locations do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :region, null: false
      t.string :city
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :event_locations, :region
    add_index :event_locations, [:event_id, :region]
    add_index :event_locations, [:region, :city]

    # Migrate existing event locations
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO event_locations (event_id, region, city, position, created_at, updated_at)
          SELECT id, region, city, 0, created_at, updated_at
          FROM events
          WHERE region IS NOT NULL
        SQL
      end
    end
  end
end
