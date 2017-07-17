class MaintenanceWorkOrderMailer < ApplicationMailer

  def work_order_notification_to_assignee(work_order)
    @work_order = work_order
    mail(to: @work_order.assigned_to.email, subject: "Lodgistics | Work Order ##{@work_order.id} assigned to you")
  end

end
