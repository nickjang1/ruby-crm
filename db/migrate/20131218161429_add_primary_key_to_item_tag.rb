class AddPrimaryKeyToItemTag < ActiveRecord::Migration
  def change
    add_column :item_tags, :id, :primary_key
  end
end
