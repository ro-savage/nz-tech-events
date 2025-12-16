class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.time :start_time
      t.time :end_time
      t.string :cost
      t.integer :event_type, null: false, default: 0
      t.string :registration_url
      t.integer :region, null: false
      t.string :city, null: false
      t.text :address
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :events, :start_date
    add_index :events, :region
    add_index :events, [ :start_date, :region ]
    add_index :events, :event_type
  end
end
