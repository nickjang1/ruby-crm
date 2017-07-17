class CreateItemsTags < ActiveRecord::Migration
  def change
    create_table :items_tags, id: false do |t|
      t.references :item
      t.references :tag
    end

    add_index :items_tags, [:item_id, :tag_id]
    add_index :items_tags, [:tag_id, :item_id]
  end
end