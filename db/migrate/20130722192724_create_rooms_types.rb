class CreateRoomsTypes < ActiveRecord::Migration
  def change
    create_table :room_types do |t|
      t.integer :average_occupancy
      t.integer :max_occupancy
      t.integer :min_occupancy
      t.string :name
      t.belongs_to :property, index: true

      t.timestamps
    end
  end
end
