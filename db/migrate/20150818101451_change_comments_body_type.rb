class ChangeCommentsBodyType < ActiveRecord::Migration
  def change
    change_column :messages, :body, :text, limit: 500
  end
end
