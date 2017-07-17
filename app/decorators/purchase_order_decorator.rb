class PurchaseOrderDecorator < Draper::Decorator
  delegate_all
  decorates_association :item_orders

  CURRENCY = 'USD'
  BTN_CLASS = { open: 'btn-danger', sent: 'btn-inverse', closed: 'btn-primary', partially_received: 'btn-inverse' }
  BTN_ICON = { open: 'ico-mail-send', sent: 'ico-truck', closed: 'ico-eye-open', partially_received: 'ico-truck' }
  BADGE_CLASS = { open: 'badge-primary', sent: 'badge-success', closed: 'badge-inverse', partially_received: 'badge-danger', fax_sending: 'badge-primary', fax_success: 'badge-success', fax_failed: 'badge-danger' }

  def total_receiving_and_freight
    object.purchase_receipts.map(&:total_w_freight).reduce(&:+) || 0
  end

  def total_freight
    Money.new(purchase_receipts.sum(:freight_shipping) *100)
  end

  def total_cost
    total_price + total_freight
  end

  def request_user
    object.purchase_request.user.try(:name)
  end

  def item_counts
    h.pluralize( object.item_orders.count, 'item')
  end

  def delivery_date
    l(purchase_order.created_at, format: :short)
  end

  def created_date
    self.created_at.to_date.strftime '%m/%d/%Y'
  end

  def badge_class
    if object.faxing?
      return BADGE_CLASS["fax_#{object.fax_last_status}".to_sym]
    end
    BADGE_CLASS[object.state.to_sym]
  end

  def btn_class
    BTN_CLASS[object.state.to_sym]
  end

  def btn_icon
    BTN_ICON[object.state.to_sym]
  end

  def btn_label
    h.t("purchase_orders.purchase_order.button_labels.#{ object.state }")
  end

  def state_label
    if object.faxing? || object.fax_success?
      h.t("purchase_orders.purchase_order.fax_statuses.#{object.fax_last_status}")
    else
      h.t("purchase_orders.purchase_order.statuses.#{ object.state }")
    end
  end

  def tooltip
    if object.fax_error?
      object.fax_last_message
    end
  end

  def vpt_xml
    builder = Builder::XmlMarkup.new(indent: 2)
    builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    builder.NewOrderRequest do |request|
      # request.RequestID self.vendor.procurement_interface.data[:vpt_request_id]
      request.PartnerInfo do |partner|
        partner.PartnerID self.vendor.procurement_interface.data[:partner_id]
        partner.UserName self.vendor.procurement_interface.data[:username]
        partner.Password self.vendor.procurement_interface.data[:password]
      end
      request.Order do |order|
        order.OrdHdr do |header|
          header.CustInfo do |vendor|
            vendor.Division   self.vendor.procurement_interface.data[:division]
            vendor.CustNbr    self.vendor.procurement_interface.data[:customer_number]
            vendor.DeptNbr    self.vendor.procurement_interface.data[:department_number]
            vendor.CustGroup  self.vendor.procurement_interface.data[:customer_group]
          end
          header.CustPONbr   "0000#{ '%05d' % self.id }"
          header.CustPODate do |date|
            date.Year   self.updated_at.year
            date.Month  self.updated_at.strftime("%m")
            date.Day    self.updated_at.strftime("%d")
          end
          header.ReqDelDate do |delivery|
            delivery_date = Date.today + 2.days
            delivery.Year   delivery_date.year
            delivery.Month  delivery_date.strftime("%m")
            delivery.Day    delivery_date.strftime("%d")
          end
        end

        self.item_orders.each do |io|
          order.OrdDtl do |detail|
            detail.ProdNbr      io.item.vendor_number(vendor.id)
            detail.CustProdNbr  'CustProdNbr' if io.item.number.nil?

            detail.QtyOrd do |qty|
              quantity = io.vpt_size
              qty.Case quantity[0]
              qty.Each quantity[1]
            end
          end
        end
      end
    end
  end

end
