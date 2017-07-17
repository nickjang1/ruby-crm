# == Schema Information
#
# Table name: item_transactions
#
#  id                 :integer          not null, primary key
#  item_id            :integer
#  type               :string(255)
#  change             :decimal(, )
#  purchase_step_type :string(255)
#  purchase_step_id   :integer
#  cumulative_total   :decimal(, )
#  created_at         :datetime
#  updated_at         :datetime
#

class InventoryTransaction < ItemTransaction
end
