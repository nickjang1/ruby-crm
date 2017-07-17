class AddTimestampsAndCreatorIdToConnection < ActiveRecord::Migration
  def change
    add_column :corporate_connections, :created_at, :datetime
    add_column :corporate_connections, :updated_at, :datetime
    add_column :corporate_connections, :created_by_id, :integer
  end
end
