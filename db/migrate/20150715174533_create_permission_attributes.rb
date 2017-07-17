class CreatePermissionAttributes < ActiveRecord::Migration
  def change
    create_table :permission_attributes do |t|
      t.integer :parent_id, default: nil
      t.string :subject
      t.string :action
      t.string :name
      t.text :options

      t.timestamps
    end

    remove_column :permissions, :subject, :string
    remove_column :permissions, :action, :string
    add_column :permissions, :permission_attribute_id, :integer
    add_column :permissions, :options, :text
  end
end
