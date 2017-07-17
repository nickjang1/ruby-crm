class DepartmentsController < ApplicationController
  add_breadcrumb I18n.t('controllers.departments.departments'), :departments_path

  before_filter :check_permissions

  def index
    scope = params[:scope] == 'deleted' && 'only_deleted' || 'all'
    @departments = Department.send(scope)
  end

  def new
    @department = Department.new
    render 'form'
  end

  def edit
    @department = Department.with_deleted.find params[:id]
    add_breadcrumb @department.name
    render 'form'
  end

  def create
    @department = Department.new
    save_department_changes
  end

  def update
    @department = Department.find(params[:id])
    save_department_changes
  end

  def destroy
    @department = Department.find(params[:id])
    @department.destroy
    redirect_to :departments, notice: I18n.t('controllers.departments.department_inactivated')
  end

  private

  def check_permissions
    authorize User, :index?
  end

  def department_params
    params.require(:department).permit(:name, category_ids: [], user_ids: [])
  end

  def save_department_changes
    @department.assign_attributes(department_params)
    if @department.save
      redirect_to :departments, notice: I18n.t('controllers.departments.department_updated', name: @department.name)
    else
      flash.now[:error] = @department.errors.full_messages.to_sentence
      render 'form'
    end
  end

end
