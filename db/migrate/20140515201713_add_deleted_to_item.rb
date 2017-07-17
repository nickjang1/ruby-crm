class AddDeletedToItem < ActiveRecord::Migration
  def change
    add_column :items, :archived, :boolean, default: false, index: true
  end
end
