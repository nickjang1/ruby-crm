class CreateNewRoleTableAndRenameOldOne < ActiveRecord::Migration
  def change
    rename_table :roles, :old_roles
    rename_table :roles_users, :old_roles_users

    rename_column :old_roles_users, :role_id, :old_role_id

    create_table :roles do |t|
      t.string :name
    end

    create_table :user_roles do |t|
      t.belongs_to :user
      t.belongs_to :role
      t.belongs_to :property
    end
  end
end
