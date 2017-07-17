class RemoveBooleanFlagsFromCorporateConnection < ActiveRecord::Migration
  def change
    remove_column :corporate_connections, :confirmed_by_corporate, :boolean
    remove_column :corporate_connections, :confirmed_by_property, :boolean
  end
end
