class MailerPreview < MailView
  def purchase_order
    Mailer.purchase_order(PurchaseOrder.not_closed.first.id)
  end

  def join_hotel_invitation
    invitation = JoinInvitation.create(sender: User.first, invitee: User.last, property: Property.first)
    Mailer.join_invitation(invitation.id)
  end

  def confirmation_instructions
    Property.current_id = Property.first.id
    user = User.where(:confirmed_at => nil).last || FactoryGirl.create(:user)
    Devise::Mailer.confirmation_instructions(user, user.confirmation_token)
  end

  def work_order_notification_to_assignee
    Property.current_id = Property.first.id
    work_order = Maintenance::WorkOrder.first
    MaintenanceWorkOrderMailer.work_order_notification_to_assignee(work_order)
  end
end
