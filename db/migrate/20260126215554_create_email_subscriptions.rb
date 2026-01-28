class CreateEmailSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :email_subscriptions do |t|
      t.string :email_address, null: false
      t.integer :region, null: false
      t.string :unsubscribe_token, null: false
      t.datetime :last_sent_at

      t.timestamps
    end

    add_index :email_subscriptions, [ :email_address, :region ], unique: true
    add_index :email_subscriptions, :unsubscribe_token, unique: true
    add_index :email_subscriptions, :region
  end
end
