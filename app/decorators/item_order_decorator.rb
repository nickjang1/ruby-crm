class ItemOrderDecorator < Draper::Decorator
  delegate_all

  def received
    "#{object.received} #{purchase_unit}"
  end

  def price
    object.average_price
  end

  def price_trend
    object.item.item_transactions.where(purchase_step_type: 'ItemReceipt').last(5).map{|transaction| transaction.purchase_step.price}.join(',')
  end

  def popover_receivings
    h.content_tag(:div) do
      object.item_receipts.each { |ir| h.concat h.content_tag(:div, "#{h.l(ir.created_at, format: :short)} | #{ir.quantity} | #{h.humanized_money_with_symbol( ir.price )}" ) }
    end
  end

  def purchase_unit
    object.item.unit
  end

  def price_unit_if_different
    different_units? ? ' ' + price_unit.name : ''
  end

  def vpt_size
    # quantity unit is EACH
    # We purchase individual units (gordon: I think that's what this means *shrug*)
    if item.price_unit_id == item.unit_id
      [self.quantity.floor, 0]
    # quantity unit is CASE
    # We purchase packs of units
    elsif item.pack_present? && item.price_unit_id == item.pack_unit_id
      self.quantity.divmod(item.pack_size).map(&:floor)
    # We purchase sub packs of units
    elsif item.pack_present? && item.subpack_present? && item.price_unit_id == item.subpack_unit_id
      size = self.quantity.divmod(item.pack_size * item.subpack_size)
      size[1] /= item.subpack_size
      size.map(&:floor)
    else
      [0, 0]
    end
  end

  private

  def price_unit
    object.item.price_unit
  end

  def different_units?
    purchase_unit != price_unit
  end
end
