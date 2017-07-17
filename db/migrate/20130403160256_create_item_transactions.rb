class CreateItemTransactions < ActiveRecord::Migration
  def change
    create_table :item_transactions do |t|
      t.references :item
      t.string :type
      t.decimal :change
      t.string :purchase_step_type
      t.integer :purchase_step_id
      t.decimal :cumulative_total

      t.timestamps
    end
    add_index :item_transactions, :item_id
  end
end
