class MoveTitleToUserRoles < ActiveRecord::Migration
  def change
    add_column :user_roles, :title, :string
    remove_column :users, :title, :string
  end
end
