class VptController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def create
    @purchase_order = PurchaseOrder.find(params[:id]).decorate
    render json: {error: t('.prepare_error')}, status: 400 and return unless @purchase_order.vpt_prepare
    @xml = @purchase_order.vpt_xml

    response = RestClient.post Settings.us_food_vpt, @xml, {accept: :xml, content_type: 'text/xml'}
    parsed_response = XmlSimple.xml_in(response.body, {'ForceArray' => false})
    if parsed_response['Error']
      render json: {error: parsed_response['Error']['Text']}, status: 400
    else
      @purchase_order.sent!
      render json: {url: parsed_response['URL']}, status: 200
    end
    # this is for test, after confirm all values with USFood, need to convert webservice side to Sidekiq Worker
    # send_data xml, filename: 'vtp.xml'
  end

end
