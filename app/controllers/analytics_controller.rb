class AnalyticsController < ApplicationController

  def index
    @items = current_property.items.order(:id)
    params[:item_id] ||= @items.first.try(:id)
    @transactions = ItemTransaction.joins(:item).where(items: {id: params[:item_id], property_id: current_property.id}).order(:cumulative_total)
    @max = @transactions.last.try(:cumulative_total)
    @min = @transactions.first.try(:cumulative_total)
    @transactions = @transactions.order(:created_at)
    @points = @transactions.map{|x|[x.created_at.to_i * 1000, x.cumulative_total.to_f]}
  end
end
