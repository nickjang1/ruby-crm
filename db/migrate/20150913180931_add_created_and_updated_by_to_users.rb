class AddCreatedAndUpdatedByToUsers < ActiveRecord::Migration
  def change
    add_column :users, :created_by, :integer
    add_column :users, :updated_by, :integer
  end
end
