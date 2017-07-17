class CreateJoinHotelInvitations < ActiveRecord::Migration
  def change
    create_table :join_hotel_invitations do |t|
      t.references :sender, index: true
      t.references :invitee, index: true
      t.references :property, index: true
      t.text :params
    end
  end
end
