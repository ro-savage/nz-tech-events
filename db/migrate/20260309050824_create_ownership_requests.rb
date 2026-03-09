class CreateOwnershipRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :ownership_requests do |t|
      t.references :event, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.text :reason, null: false
      t.integer :status, null: false, default: 0
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :ownership_requests, [ :status, :created_at ]
    add_index :ownership_requests, [ :event_id, :status, :created_at ]
    add_index :ownership_requests, [ :event_id, :requester_id ],
              unique: true,
              where: "status = 0",
              name: "index_ownership_requests_on_event_and_requester_pending"
  end
end
