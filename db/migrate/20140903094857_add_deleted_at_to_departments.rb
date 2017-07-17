class AddDeletedAtToDepartments < ActiveRecord::Migration
  def change
    add_column :departments, :deleted_at, :datetime
  end
end
