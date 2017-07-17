class AddVptFieldsToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :vpt_partner_id, :string
    add_column :properties, :vpt_username, :string
    add_column :properties, :vpt_password, :string
  end
end
