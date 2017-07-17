class AddTitleAndOrderApprovalLimitToUsers < ActiveRecord::Migration
  def change
    add_column :users, :title, :string
    add_column :users, :order_approval_limit, :decimal, default: 0
  end
end
