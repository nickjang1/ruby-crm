class ActivitiesController < ApplicationController
  def index
    @activities = PublicActivity::Activity.where(recipient: Property.current)
    respond_to do |format|
      format.html do
        @from = PublicActivity::Activity.where(recipient: Property.current).minimum :created_at
        @to = PublicActivity::Activity.where(recipient: Property.current).maximum :created_at
        @from = @from.strftime('%m/%d/%Y') if @from
        @to = @to.strftime('%m/%d/%Y') if @to
        @owners = @activities.distinct(:owner_id).map { |m| [m.owner.try(:name), m.owner.try(:id)] }
        @owners.uniq! { |a| a.last }
        @owners.unshift(['Select user(s) to filter activities', nil])
      end
      format.json do
        @q = @activities.ransack(params[:ransack])
        @activities = @q.result.page(params[:page]).per(10).order(created_at: :desc)
        render 'index'
      end
    end
  end
end
