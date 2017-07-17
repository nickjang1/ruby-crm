class ModifyPermissions < ActiveRecord::Migration
  def self.up
    db.execute 'DELETE FROM permissions'

    remove_column :permissions, :subject_type, :string
    remove_column :permissions, :subject_id, :integer
    add_column :permissions, :department_id, :integer
    add_column :permissions, :subject, :string
    add_column :permissions, :property_id, :integer
  end

  def self.down
    add_column :permissions, :subject_type, :string
    add_column :permissions, :subject_id, :integer
    remove_column :permissions, :department_id, :integer
    remove_column :permissions, :subject, :string
    remove_column :permissions, :property_id, :integer
  end

  private

  def db
    ActiveRecord::Base.connection
  end
end
