class CreateMagicTags < ActiveRecord::Migration
  def change
    create_table :magic_tags do |t|
      t.string :name
      t.text :text
      t.integer :property_id
      t.integer :created_by_id

      t.timestamps
    end
  end
end
