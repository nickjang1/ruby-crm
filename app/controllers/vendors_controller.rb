class VendorsController < ApplicationController
  add_breadcrumb I18n.t('controllers.vendors.vendors'), :vendors_path
  before_filter :authenticate_user!
  respond_to :html
  before_action :load_vendor, only: :create
  load_and_authorize_resource except: [:index]

  def check_permissions
    authorize!(params[:action].to_sym, Vendor)
  end

  def index
    authorize!(:index, Vendor)
    @vendors = Vendor.order('name asc')
  end

  def new
    params[:active] ||= 'profile'
    add_breadcrumb t('controllers.vendors.title_new')
  end

  def edit
    params[:active] ||= 'profile'
    add_breadcrumb t('controllers.vendors.title_new')
  end

  def create
    if @vendor.save
      redirect_to vendors_url, notice: t('controllers.vendors.vendor_was_created')
    else
      render action: 'new'
    end
  end

  def update
    if @vendor.update_attributes(vendor_params)
      redirect_to vendors_url, notice: t('controllers.vendors.vendor_was_updated')
    else
      render action: 'edit'
    end
  end

  def destroy
    if @vendor.destroy
      redirect_to vendors_url, notice: t('controllers.vendors.vendor_was_deleted')
    else
      redirect_to vendors_url, alert: @vendor.errors.full_messages.to_sentence.capitalize
    end
  end

  protected

  def load_vendor
    @vendor = Vendor.new(vendor_params)
  end

  def vendor_params
    params.require(:vendor).permit :name, :street_address, :zip_code, :city, :email, :phone, :fax, :contact_name, 
      :shipping_method, :shipping_terms, :division, :customer_number, :department_number, :customer_group, :vpt_enabled,
      procurement_interface_attributes: [:interface_type, :id, data: ProcurementInterface::TYPE_SETTINGS.values.map{ |setting| setting[:fields] }.flatten.uniq ]
  end
end
