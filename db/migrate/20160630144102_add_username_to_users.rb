class AddUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string
    change_column :users, :email, :string, null: true
  end
end
