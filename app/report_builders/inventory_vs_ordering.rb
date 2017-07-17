class InventoryVsOrdering
  def initialize(item, range)
    @item = item
    @range = range
  end

  def average_orders
    avg = @item.item_orders.where(created_at: @range).count.to_f / num_completed_months 
    '%.2f' % avg
  end

  def average_counts
    avg = @item.item_requests.where(created_at: @range, skip_inventory: nil).count.to_f / num_completed_months
    '%.2f' % avg
  end

  def last_order_at
    formatted_created_at(@item.item_orders.order(:created_at).last)
  end

  def last_count_at
    formatted_created_at(@item.item_requests.where(skip_inventory: nil).order(:created_at).last)
  end

  private
  def formatted_created_at(resource)
    return 'never' if resource.nil?
    I18n.l(resource.created_at, format: :short)
  end

  def num_completed_months
    first_month = @range.first.month
    last_month = @range.last > Date.today ? Date.today.month : @range.last.month
    ( 1 + last_month - first_month)
  end
end
