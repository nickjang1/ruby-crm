class AddLastUserIdToOrder < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :last_user_id, :integer
  end
end
