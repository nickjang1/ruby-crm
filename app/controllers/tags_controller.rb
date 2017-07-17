class TagsController < ApplicationController
  respond_to :html

  before_filter :authenticate_user!
 
  def index
    @q = model.accessible_by(current_ability).roots_and_descendants_preordered.search(params[:q])
    @tags = @q.result
    respond_with @tags
  end

  def new
    @tag = model.new
    @excluded_items = Item.where{id.not_in my{@tag.items.map(&:id)}}
    respond_with @tag
  end

  def edit
    add_breadcrumb tag.name
    @excluded_items = Item.where{id.not_in my{tag.items.map(&:id)}}
    respond_with tag
  end

  def create
    @tag = model.new(tag_params.merge(property: current_property))
    @tag.user = current_user
    @tag.update_attribute(:siblings_position, :last) unless tag_params[:operation]
    if @tag.save && @tag.update_items(params)
      flash[:notice] = t("controllers.tags.tag_created", model: model)
      redirect_to model  
    else
      render action: 'new'
    end
  end

  def update
    if tag.update_attributes(tag_params) && tag.update_items(params)
      flash[:notice] = t("controllers.tags.tag_updated", tag_type_h: tag_type_h, tag_name: tag.name)
      redirect_to action: 'index'
    else
      flash.now[:error] = tag.errors.full_messages.to_sentence
      render action: 'edit'
    end
  end

  def destroy
    tag.destroy
    flash[:notice] = t("controllers.tags.tag_deleted", tag_name: model.to_s.downcase)
    redirect_to model
  end

  protected

  def tag_type
    params[:controller]
  end

  def tag_type_h
    tag_type.singularize.capitalize
  end

  helper_method :tag_type_h, :tag_type
  
  def tag_params
    params.require(:tag).permit(:name, :type, :unboxed_countable, :operation, :other_id, item_ids: [])
  end

  def model
    @model ||= tag_type.classify.constantize
  end
  
  def tag
    return nil unless params[:id]
    @tag ||= model.find(params[:id])
  end
end
