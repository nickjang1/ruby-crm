class AddDeletedAtToUserRole < ActiveRecord::Migration
  def change
    add_column :user_roles, :deleted_at, :datetime, default: nil
    add_index :user_roles, :deleted_at
  end
end
