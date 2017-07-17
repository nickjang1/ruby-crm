class RemoveCorpIdFromProperty < ActiveRecord::Migration
  def change
    remove_column :properties, :corporate_id
  end
end
