class AddCorporateIdToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :corporate_id, :integer
  end
end
