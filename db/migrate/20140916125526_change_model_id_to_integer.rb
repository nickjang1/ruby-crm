class ChangeModelIdToInteger < ActiveRecord::Migration
  def change
    change_column :notifications, :model_id, 'integer USING CAST(model_id AS integer)'
  end
end
