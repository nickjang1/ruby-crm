class AddTimestampsForRequest < ActiveRecord::Migration
  def change
    add_column :purchase_requests, :approved_at, :datetime
  end
end
