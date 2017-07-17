class CreateRoomForecasts < ActiveRecord::Migration
  def change
    create_table :room_occupancies do |t|
      t.integer :actual
      t.integer :forecast
      t.belongs_to :room_type, index: true
      t.date :date

      t.timestamps
    end
  end
end
