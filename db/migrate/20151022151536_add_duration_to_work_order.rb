class AddDurationToWorkOrder < ActiveRecord::Migration
  def change
    add_column :maintenance_work_orders, :duration, :integer
  end
end
