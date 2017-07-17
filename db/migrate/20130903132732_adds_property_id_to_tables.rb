class AddsPropertyIdToTables < ActiveRecord::Migration
  def change
    add_reference :tags, :property, index: true
  end
end
