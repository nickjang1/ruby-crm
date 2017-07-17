class AddRankOrderToEquipments < ActiveRecord::Migration
  def change
    add_column :maintenance_equipment, :row_order, :integer
  end
end
