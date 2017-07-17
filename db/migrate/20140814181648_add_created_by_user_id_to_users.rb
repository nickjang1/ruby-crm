class AddCreatedByUserIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :created_by_user_id, :integer
  end
end
