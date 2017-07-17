class ListsController < TagsController
  before_filter :check_permissions
  add_breadcrumb I18n.t('controllers.lists.lists'), :lists_path, :options => { :title => "Lists" }

  def check_permissions
    authorize!(params[:action].to_sym, tag || List)
  end
end
