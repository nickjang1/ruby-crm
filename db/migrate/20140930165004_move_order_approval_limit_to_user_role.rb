class MoveOrderApprovalLimitToUserRole < ActiveRecord::Migration
  def self.up
    add_column :user_roles, :order_approval_limit, :decimal, default: 0
    UserRole.reset_column_information
    Property.all.each do |prop|
      Property.current_id = prop.id
      prop.users.each do |u|
        u_role = u.current_property_user_role
        u_role.update_attributes(order_approval_limit: u.order_approval_limit)
      end
    end
    # remove_column :users, :order_approval_limit
  end

  def self.down
    remove_column :user_roles, :order_approval_limit
  end
end
