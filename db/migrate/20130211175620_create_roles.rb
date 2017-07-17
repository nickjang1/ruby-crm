class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.references :property
      t.string :name
      t.integer :position

      t.timestamps
    end
    add_index :roles, :property_id
  end
end
