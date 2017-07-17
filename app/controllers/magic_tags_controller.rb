class MagicTagsController < ApplicationController

  def index
    @magic_tags = MagicTag.all
  end

  def new
    @magic_tag = MagicTag.new
  end

  def create
    @magic_tag = MagicTag.new(magic_tag_params)
    if @magic_tag.save
      redirect_to magic_tags_path, notice: "Magic Tag #{@magic_tag.name} has been saved."
    else
      render :new
    end
  end

  def edit
    @magic_tag = MagicTag.find params[:id]
  end

  def update
    @magic_tag = MagicTag.find params[:id]
    if @magic_tag.update_attributes(magic_tag_params)
      redirect_to magic_tags_path, notice: "Magic Tag #{@magic_tag.name} has been updated."
    else
      render :edit
    end
  end

  def destroy
    @magic_tag = MagicTag.find params[:id]
    if @magic_tag.destroy
      redirect_to magic_tags_path, notice: "Magic Tag #{@magic_tag.name} has been deleted."
    else
      redirect_to magic_tags_path, alert: "Failed to delete magic tag."
    end
  end

  private

  def magic_tag_params
    params.require(:magic_tag).permit(:name, :text, :created_by_id)
  end

end