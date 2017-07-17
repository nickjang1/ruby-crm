class AddTimeZoneToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :time_zone, :string, default: "Eastern Time (US & Canada)"
  end
end
