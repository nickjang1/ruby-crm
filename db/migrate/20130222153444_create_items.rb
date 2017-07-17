class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :name
      t.string :number
      t.decimal :count
      t.references :unit, index: true
      t.integer :frequency
      t.decimal :par_level
      t.attachment :image
      t.integer :item_transactions_count, :default => 0

      t.timestamps
    end
  end
end
