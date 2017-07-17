class ChangeBodyEncrytedInComments < ActiveRecord::Migration
  def change
    rename_column :comments, :body, :encrypted_body
  end
end
