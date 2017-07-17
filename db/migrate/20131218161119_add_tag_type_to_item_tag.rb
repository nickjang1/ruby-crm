class AddTagTypeToItemTag < ActiveRecord::Migration
  def change
    add_column :item_tags, :tag_type, :string
  end
end
