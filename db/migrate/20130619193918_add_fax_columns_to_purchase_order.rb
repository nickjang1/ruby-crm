class AddFaxColumnsToPurchaseOrder < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :fax_id, :integer
    add_column :purchase_orders, :fax_last_status, :string
    add_column :purchase_orders, :fax_last_message, :string
  end
end
