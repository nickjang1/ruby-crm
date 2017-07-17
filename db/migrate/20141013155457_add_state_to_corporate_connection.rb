class AddStateToCorporateConnection < ActiveRecord::Migration
  def change
    add_column :corporate_connections, :state, :string
  end
end
