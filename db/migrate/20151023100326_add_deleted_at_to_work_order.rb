class AddDeletedAtToWorkOrder < ActiveRecord::Migration
  def change
    add_column :maintenance_work_orders, :deleted_at, :datetime, default: nil
  end
end
