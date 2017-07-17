class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string   :type
      t.string   :name
      t.boolean  :unboxed_countable
      t.integer  :parent_id
      t.integer  :position
      
      t.timestamps
    end
  end
end
