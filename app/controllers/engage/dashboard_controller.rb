class Engage::DashboardController < ApplicationController
  before_filter :authenticate_user!
  around_filter :property_time_zone
  add_breadcrumb I18n.t('controllers.engage.dashboard'), :engage_dashboard_path

  def index
    respond_to do |format |
      format.html {}
      format.pdf do
        @date = Date.parse(params[:date] || Date.today.to_s)
        @messages = Engage::Message.threads.occurred_on(@date).as_json(user: current_user, date: @date)
        @follow_ups = @messages.select { |msg| msg[:follow_up_show] }
        @messages = @messages - @follow_ups

        @alarms = Engage::Entity.alarm(@date).as_json(user: current_user, date: @date)

        title = format("Front Desk Log")
        render pdf: title,
               template: 'engage/dashboard/index',
               layout: 'layouts/pdf.html.haml',
               header: {
                 html: {
                   template: 'reports/pdf/header',
                   locals: {
                     report_title: title
                   }
                 },
                 spacing: -10
               },
               footer: {
                 center: '[page] of [topage]'
               }
      end
    end
  end
end
