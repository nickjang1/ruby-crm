class RenameJoinHotelInvitationToJoinInvitation < ActiveRecord::Migration
  def up
    rename_table :join_hotel_invitations, :join_invitations
    add_column :join_invitations, :targetable_id, :integer
    add_column :join_invitations, :targetable_type, :string

    db.execute 'UPDATE join_invitations SET targetable_id=property_id'
    db.execute "UPDATE join_invitations SET targetable_type='Property'"

    remove_column :join_invitations, :property_id
  end

  def down
    add_column :join_invitations, :property_id, :integer
    db.execute "UPDATE join_invitations SET property_id=targetable_id WHERE targetable_type='Property'"
    remove_column :join_invitations, :targetable_id
    remove_column :join_invitations, :targetable_type
    rename_table :join_invitations, :join_hotel_invitations
  end

  private

  def db
    ActiveRecord::Base.connection
  end
end
