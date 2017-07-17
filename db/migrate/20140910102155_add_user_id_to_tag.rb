class AddUserIdToTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :user_id, :integer

    Tag.unscoped.all.each do |tag|
      Property.current_id = tag.property_id
      user = tag.property.users.first
      tag.update_attributes(user_id: user.id) if user
    end
  end

  def self.down
    remove_column :tags, :user_id, :integer
  end
end
