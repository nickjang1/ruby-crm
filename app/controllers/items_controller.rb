class ItemsController < ApplicationController
  add_breadcrumb I18n.t("controllers.items.items"), :items_path
  before_filter :authenticate_user!
  before_action :load_item, only: :create
  # before_action :load_items, only: :index
  before_action :load_categories, only: [:new, :edit]
  load_and_authorize_resource except: [:index]
  respond_to :html

  def index
    authorize! :index, Item
    accessible_items = Item.accessible_by(current_ability).includes(:vendors)
    unless params[:search].blank?
      for column_name, query in params[:search]
        accessible_items = accessible_items.search_columns(column_name.to_sym, query) unless query.blank?
      end
    end
    @total_items_count = accessible_items.count
    @items = accessible_items.page(params[:page]).per(10)
    respond_to do |fmt|
      fmt.html
      fmt.json
    end
  end

  def new
    add_breadcrumb t("controllers.items.breadcrumb_new")
    @item.build_unit
    @item.vendor_items.build unless @item.vendor_items.first
  end

  def edit
    add_breadcrumb t("controllers.items.breadcrumb_edit", number: @item.number)
    @item.build_unit unless @item.unit
    @item.vendor_items.build unless @item.vendor_items.first
  end

  def edit_multiple_tags
    @items = Item.where(id: params[:selected_item_ids])
    respond_with @items do |format|
      format.html {render layout: false}
    end
  end

  def new_import
    add_breadcrumb t('controllers.items.import')
  end

  def import
    if params[:template].blank?
      flash[:error] = t('controllers.items.need_to_select_file')
      redirect_to items_url
    elsif @items = ItemIngestion.read_excel(current_property, params[:template])
      logger.fatal @items.inspect
      redirect_to items_url, notice: t('controllers.items.import_successful', file_name: params[:template].original_filename, items_count: @items.count) 
    else
      flash[:error] = t('controllers.items.failed_to_upload_template')
      redirect_to items_url
    end
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to :items, notice: t('controllers.items.item_created')
    else
      @item.build_unit unless @item.unit
      render action: 'new'
    end
  end

  def update
    result = @item.update_attributes(item_params)
    respond_to do |fmt|
      fmt.html do
        if result
          redirect_to :items, notice: t('controllers.items.item_updated')
        else
          render action: 'edit'
        end
      end
      fmt.json do
        if result
          render json: true, status: 200
        else
          render json: true, status: 422
        end
      end
    end
  end

  def update_multiple_tags
    @items = Item.find(params[:selected_item_ids])
    @items.each do |item|
      item.tag_ids |= item_params[:tag_ids]
      item.save
    end
    redirect_to items_path, notice: t('controllers.items.items_updated')
  end

  def destroy
    @items = Item.where(id: params[:ids]).destroy_all
    redirect_to items_path, notice: t('controllers.items.items_deleted')
  end

private
  def load_item
    @item = Item.new(item_params)
  end

  def load_items
    if current_user.current_property_role.manager?
      @items = Item.find( ItemTag.where(tag_id: current_user.category_ids.uniq ).map(&:item_id) )
    end
  end

  def load_categories
    @categories = current_user.current_property_role.manager? ? current_user.categories : Category.all
  end

  def item_params
    params.require(:item).permit :name, :description, :brand_id, :is_asset, :category_ids, :purchase_cost_unit_id, :purchase_cost, {tag_ids: []}, 
      {location_ids: []}, :par_level, :is_taxable, :pack_size,
      :price, :unit_id, :subpack_unit_id, :pack_unit_id, :unit_subpack,
      :subpack_size, :inventory_unit_id, :price_unit_id,
      unit_attributes: [:name, :description],
      pack_attributes: [:name, :description],
      subpack_attributes: [:name, :description],
      vendor_items_attributes: [:id, :vendor_id, :price, :items_per_box, :sku, :preferred, :_destroy]
  end
end
