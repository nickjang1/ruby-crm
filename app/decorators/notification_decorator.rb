class NotificationDecorator < Draper::Decorator
  delegate_all

  ICON_CLASS = { 
    'fax.sent' => 'ico-shopping-cart bgcolor-success', 
    'fax.failed' => 'ico-shopping-cart bgcolor-danger',
    'request.approve' => 'ico-basket2 bgcolor-success',
    'request.approved' => 'ico-basket2 bgcolor-success',
    'request.rejected' => 'ico-basket2 bgcolor-danger',
    'work_order.assigned' => 'ico-tools bgcolor-primary'
  }

  def icon
    ICON_CLASS[object.ntype]
  end

  def link
    case object.ntype
      when 'fax.sent', 'fax.failed'
        h.purchase_order_path object.model_id
      when 'request.approve', 'request.rejected'
        h.edit_purchase_request_path object.model_id
      when 'request.approved'
        h.purchase_order_path PurchaseRequest.find(object.model_id).purchase_orders.first
      when 'work_order.assigned'
        h.maintenance_work_orders_path(id: object.model_id)
      else
        raise "Unknown notification type : #{object.ntype}"
    end
  end

  def method
    case object.ntype
      when 'fax.sent', 'fax.failed'
        "GET"
      when 'request.approve', 'request.approved', 'request.rejected'
        "GET"
      when 'work_order.assigned'
        'GET'
      else
        raise "Unknown notification type : #{object.ntype}"
    end
  end

end
