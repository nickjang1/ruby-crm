class Admin::CustomersController < Admin::BaseController

  def new
    add_breadcrumb 'Setup New Customer'
  end

  def create
    corporate_params = params[:corporate].extract! :name, :username, :useremail
    properties = params[:corporate].delete :properties
    message = {}
    ActiveRecord::Base.transaction do
      @corporate = Corporate.create_corporate corporate_params
      message[:alert] = 'User is part of another Corporate site. Please use another email or contact support.' if @corporate.nil?
      @properties = []
      properties.each do |key, value|
        property_params = value.extract! :name, :username, :useremail, :time_zone
        property = Property.create_property @corporate, property_params
        @properties << property if property
      end
    end

    if @corporate || @properties.count > 0
      # render :create
    else
      render :new
    end
  end

  def show
    @corporate = Corporate.find params[:id]
  end
end