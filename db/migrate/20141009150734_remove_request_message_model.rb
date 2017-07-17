class RemoveRequestMessageModel < ActiveRecord::Migration

  def change
    execute "TRUNCATE messages;"
    drop_table :request_messages if ActiveRecord::Base.connection.table_exists? :request_messages
    rename_column :messages, :purchaes_request_id, :messagable_id
    add_column :messages, :messagable_type, :string
  end

end
