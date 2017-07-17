class CreateEngageMessages < ActiveRecord::Migration
  def change
    create_table :engage_messages do |t|
      t.references :property, index: true
      t.string :title
      t.text :encrypted_body
      t.string :room_number
      t.integer :created_by_id
      t.date :broadcast_start
      t.date :broadcast_end
      t.integer :work_order_id
      t.datetime :completed_at
      t.integer :completed_by_id
      t.date :follow_up_start
      t.date :follow_up_end
      t.integer :parent_id, default: nil

      t.timestamps
    end
  end
end
