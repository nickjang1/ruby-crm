class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.references :role
      t.string :subject_type
      t.integer :subject_id
      t.string :action

      t.timestamps
    end
    add_index :permissions, :role_id
  end
end
