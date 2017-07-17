class RenameColumn < ActiveRecord::Migration
  def change
    rename_column :maintenance_records, :last_updated_at, :completed_on
  end
end
