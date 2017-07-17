class AddOrdinalityNumberToMaintenanceCycle < ActiveRecord::Migration
  def change
    add_column :maintenance_cycles, :ordinality_number, :integer
  end
end
