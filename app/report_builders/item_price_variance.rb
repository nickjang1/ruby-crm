class ItemPriceVariance
  def initialize(item, range)
    @item = item
    @range = range
  end

  # of Vendors [Calculated as the total number of unique vendors the item has Orders for, in the given time range]
  def num_orders
    item_receipts = @item.item_receipts.where(created_at: @range).includes(:item_order)
    po_ids = item_receipts.map{|ir| ir.item_order.purchase_order_id }.uniq
    purchase_orders = PurchaseOrder.find(po_ids)

    purchase_orders.count
  end

  #Average Price ( average Received price of the item for all the receivings in the selected time period)
  def average_price
    item_receipts = @item.item_receipts.where(created_at: @range)
    return '0' unless item_receipts.present?
    result = item_receipts.sum(:price) / item_receipts.count
    Money.new(result * 100).to_s
  end

  def item_receipts_with_variance
    @item.item_receipts.where(created_at: @range).includes(:item_order).where('item_receipts.price <> item_orders.price').references(:item_orders)
  end

  #% Average Variance (Calculate with absolute value of the difference between the order price and the received price = [Total Absolute Difference / Total # of Receivings with difference between ordered and received prices])
  def average_variance
    return '0' unless item_receipts_with_variance.present?
    result = item_receipts_with_variance.map{ |ir| (ir.price - ir.item_order.price).abs }.reduce(&:+) / item_receipts_with_variance.count
    Money.new(result * 100).to_s
  end

  def item_receivings_with_higher_price
    @item_receivings_with_higher_price ||= @item.item_receipts.where(created_at: @range).includes(:item_order).where('item_receipts.price > item_orders.price').references(:item_orders)
  end

  def average_received_price_higher
    item_receivings_with_higher_price.sum(:price) / item_receivings_with_higher_price.count
  end

  def average_ordered_price_higher
    item_receivings_with_higher_price.sum('item_orders.price') / item_receivings_with_higher_price.count
  end

  #% Increase (Calculate with absolute value of the difference between the order price and the received price WHEN Received price is GREATER than the order price = 
  #[Total Positive Difference between Received price & Order Price / Total # of Receivings with positive difference between received and ordered prices])
  def increase
    return '0' unless item_receivings_with_higher_price.present?
    increase = (average_received_price_higher - average_ordered_price_higher) / average_ordered_price_higher * 100
    '%.0f' % increase
  end
end
