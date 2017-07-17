class AddCorporateIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :corporate_id, :integer
  end
end
