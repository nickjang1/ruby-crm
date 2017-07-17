class AddItemNumterToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :number, :integer
    
    Item.all.each do |item|
      item.number = item.id
      item.save
    end
  end
  
  def self.down
    remove_column :items, :number
  end
end
