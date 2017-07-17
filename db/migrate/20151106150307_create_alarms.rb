class CreateAlarms < ActiveRecord::Migration
  def change
    create_table :alarms do |t|
      t.references :property
      t.references :user
      t.datetime :alarm_at
      t.text :body
      t.integer :checked_by
      t.datetime :checked_on
      t.timestamps
    end
  end
end
