class CreateMaintenanceCycle < ActiveRecord::Migration
  def change
    create_table :maintenance_cycles do |t|
      t.references :user, index: true
      t.references :property, index: true
      t.integer :year
      t.integer :start_month
      t.integer :frequency_months
      t.string :cycle_type

      t.timestamps
    end
  end
end
