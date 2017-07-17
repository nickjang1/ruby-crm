class CreateUserListUsages < ActiveRecord::Migration
  def change
    create_table :user_list_usages do |t|
      t.integer :user_id
      t.integer :list_id

      t.timestamps
    end
  end
end
