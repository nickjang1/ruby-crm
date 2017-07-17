class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :user
      t.references :property

      t.string :ntype
      t.string :model_id
      t.string :message
      t.boolean :read, default: false

      t.timestamps
    end
  end
end
