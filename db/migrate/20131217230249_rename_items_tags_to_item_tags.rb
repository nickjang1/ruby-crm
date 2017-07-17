class RenameItemsTagsToItemTags < ActiveRecord::Migration
  def change
    rename_table :items_tags, :item_tags
  end
end
