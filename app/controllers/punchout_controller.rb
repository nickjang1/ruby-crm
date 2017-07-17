class PunchoutController < ApplicationController

  before_action :load_vendor, only: [:create, :shopping_cart]

  def create
    setup_request = @vendor.punchout_setup_request
    response = RestClient.post Settings.punchout_setup_request_url, setup_request, {accept: :xml, content_type: 'text/xml'}
    parsed = XmlSimple.xml_in(response.body, {'ForceArray' => false})['Response']
    if parsed['Status'] != '200'
      @message = parsed['Status']['content']
      render :error
    else
      redirect_to parsed['PunchOutSetupResponse']['URL']
    end
  end

  def shopping_cart
    response = XmlSimple.xml_in(request.body, {'ForceArray' => false})
    if @vendor.process_order_request(response)
      render nothing: true
    else
      render nothing: true, status: 400
    end
  end

  private
  def load_vendor
    Property.current_id = params[:property_id]
    @vendor = Vendor.find(params[:vendor_id]).decorate
  end

end