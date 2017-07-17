class AddSettingsToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :settings, :text
  end
end
