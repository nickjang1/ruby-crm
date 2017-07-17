class Maintenance::BaseController < ApplicationController
  before_filter :authenticate_user!
  before_action :check_permissions
  before_action :check_current_cycles_are_finished

  add_breadcrumb I18n.t("controllers.maintenance.root"), :maintenance_root_path

  private

  def check_permissions
    authorize :access, :maintenance?
  end

  # returns an array of cycles that are finished by the moment of checking
  # example: [:room]
  def check_current_cycles_are_finished
    finished_cycles = Maintenance::Cycle::CYCLE_TYPES
    .map{ |c_type| current_cycle(c_type) }.compact
    .select{ |cycle| cycle.is_over? }
    # to test messages uncomment next line:
    # finished_cycles = [current_cycle(:room), current_cycle(:public_area)]
    messages = render_to_string(partial: 'maintenance/shared/cycle_expired_alert', locals: {finished_cycles: finished_cycles})
    flash[:sticky_messages] = [[:alert, messages]] if finished_cycles.any?
  end

  def send_notification_and_mail_to_assignee(work_order)
    if @work_order.assigned_to
      MaintenanceWorkOrderMailer.work_order_notification_to_assignee(work_order).deliver!
      Notification.assigned_work_order(work_order)
      WorkOrderWorker.perform_async(work_order.id)
    end
  end

  def authorize_maintenance
    authorize :access, :pm?
  end

  def authorize_inspection
    authorize :access, :inspection?
  end

  def authorize_work_order
    authorize :access, :work_order?
  end

  def authorize_pm_setup
    authorize :access, :pm_setup?
  end

end

