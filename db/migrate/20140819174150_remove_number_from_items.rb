class RemoveNumberFromItems < ActiveRecord::Migration
  def up
    remove_column :items, :number

    max_id = Item.maximum("id") || 0
    execute "SELECT setval('items_id_seq', #{max_id + 10000});"
  end

  def down
    add_column :items, :number, :integer
  end
end
