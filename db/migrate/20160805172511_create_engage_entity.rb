class CreateEngageEntity < ActiveRecord::Migration
  def change
    create_table :engage_entities do |t|
      t.integer   :property_id
      t.text      :body
      t.string    :room_number
      t.string    :entity_type
      t.integer   :created_by_id
      t.integer   :completed_by_id
      t.datetime  :completed_at
      t.datetime  :due_date
      t.string    :status
      t.hstore    :metadata

      t.timestamps
    end
  end
end
