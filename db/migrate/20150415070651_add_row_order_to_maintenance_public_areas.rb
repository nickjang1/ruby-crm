class AddRowOrderToMaintenancePublicAreas < ActiveRecord::Migration
  def change
    add_column :maintenance_public_areas, :row_order, :integer
  end
end
