class ChangeWoDueToToDate < ActiveRecord::Migration
  def change
    change_column :maintenance_work_orders, :due_to_date, :date
  end
end
