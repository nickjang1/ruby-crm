class AddVptRequestIdToPo < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :vpt_request_id, :string
  end
end
