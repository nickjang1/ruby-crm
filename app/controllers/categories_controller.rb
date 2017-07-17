class CategoriesController < TagsController
  add_breadcrumb I18n.t('controllers.categories.categories'), :categories_path, :options => { :title => "Categories" }
end
