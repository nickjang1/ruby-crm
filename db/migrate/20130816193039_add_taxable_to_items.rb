class AddTaxableToItems < ActiveRecord::Migration
  def change
    add_column :items, :taxable, :boolean
  end
end
