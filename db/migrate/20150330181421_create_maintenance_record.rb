class CreateMaintenanceRecord < ActiveRecord::Migration
  def change
    create_table :maintenance_records do |t|
      t.references :user, index: true
      t.references :cycle, index: true

      t.string :maintainable_type
      t.integer :maintainable_id
      t.string :status
      t.text :notes
      t.datetime :started_at, default: nil
      t.datetime :last_updated_at, default: nil
      t.datetime :spot_check_at, default: nil
      t.integer :spot_check_by_id, default: nil
      t.text :spot_check_notes

      t.timestamps
    end
  end
end
