class PopulateItemNumberField < ActiveRecord::Migration
  def up
    db.select_values("SELECT id FROM properties").each do |property_id|
      items = db.select_values("SELECT id FROM items WHERE items.property_id=#{property_id} ORDER BY created_at DESC")
      items.each_with_index do |item_id, index|
        db.execute "UPDATE items SET number=#{index + 10000} WHERE items.id = #{item_id}"
      end
    end
  end

  def down
  end

  private
  def db
    ActiveRecord::Base.connection
  end
end
