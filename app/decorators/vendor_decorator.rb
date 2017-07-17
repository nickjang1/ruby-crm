class VendorDecorator < Draper::Decorator
  delegate_all

  def punchout_setup_request
    payload_id = generate_payload_id
    update_attribute(:payload_id, payload_id)

    builder = Builder::XmlMarkup.new(indent: 2)
    builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    builder.cXML(version: '1.2.009', payloadID: payload_id, timestamp: Time.now.iso8601) do |doc|
      punchout_header(doc)
      doc.Request(deploymentMode: Rails.env) do |req|
        req.PunchoutSetupRequest(operation: 'create') do |setup_request|
          setup_request.BuyerCookie 'test-cookie'
          setup_request.BrowserFormPost do |form|
            form.URL h.punchout_shopping_cart_url(Property.current_id, id)
          end
        end
      end
    end
  end

  def process_order_request(response)
    payload_id = response['payloadID']
    return false if self.payload_id.nil? || self.payload_id != payload_id
    message = response['Message']['PunchOutOrderMessage']

    header = message['PunchOutOrderMessageHeader']
    total = header['Total']['Money']['content'].to_f

    item_in = message['ItemIn']
    quantity = item_in['quantity'].to_i
    line_number = item_in['lineNumber']
    item_supplier_part_id = item_in['ItemID']['SupplierPartID']

    item_detail = item_in['ItemDetail']
    unit_price = item_detail['UnitPrice']['Money']['content'].to_f
    item_desc = item_detail['Description']['content']
    unit = item_detail['UnitOfMeasure']
    true
  end

  def order_request
    payload_id = "#{Time.now.to_i}.process@#{Settings.external_host}"
    timestamp = Time.now.iso8601

    builder = Builder::XmlMarkup.new(indent: 2)
    builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    builder.cXML(version: '1.2.009', payloadID: payload_id, timestamp: timestamp) do |doc|
      punchout_header(doc)
      doc.Request(deploymentMode: Rails.env) do |req|
        req.OrderRequest do |order_request|
          order_request.OrderRequestHeader(orderID: '000000000000352', orderDate: Date.today, type: 'new') do |header|
            header.Total do |total|
              total.Money '49.99'
            end
            header.ShipTo do |ship|
              ship.Address do |address|
              end
            end
            header.BillTo do |bill|
              bill.Address do |address|
              end
            end
            header.Shipping do |shipping|
              shipping.Money '0'
            end
          end
          order_request.ItemOut(quantity: 5, lineNumber: '1', requestedDeliveryDate: Date.today) do |item_out|
            item_out.ItemID do |item_id|
              item_id.SupplierPartID '0005410'
            end
            item_out.ItemDetail do |detail|
              detail.UnitPrice do |unit_price|
                unit_price.Money '9.99'
              end
              detail.Description 'Cotton Terry Bath Mat White 20x34'
              detail.UnitOfMeasure 'DZ'
            end
          end
        end
      end
    end
  end

  private
  def generate_payload_id
    "#{Time.now.to_i}.#{SecureRandom.random_number(10**6)}@#{Settings.external_host}"
  end

  def punchout_header(builder)
    username = procurement_interface.data[:username]
    password = procurement_interface.data[:password]
    builder.Header do |header|
      header.From do |from|
        from.Credential(domain: 'NetworkID') do |credential|
          credential.Identify 'WYND'
        end
      end
      header.To do |to|
        to.Credential(domain: Settings.external_host) do |credential|
          credential.Identify '1234567890'
        end
      end
      header.Sender do |sender|
        sender.Credential(domain: Settings.external_host) do |credential|
          credential.Identify username
          credential.SharedSecret password
        end
        sender.UserAgent 'V7'
      end
    end
    builder
  end
end
