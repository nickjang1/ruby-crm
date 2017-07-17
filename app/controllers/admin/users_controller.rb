class Admin::UsersController < Admin::BaseController

  def edit
    @admin = Admin.find params[:id]
  end

  def update
    @admin = Admin.find params[:id]
    if @admin.update_attributes admin_attributes
      redirect_to edit_admin_user_path(@admin), notice: 'You have updated password successfully.'
    else
      render :edit
    end
  end

  private

  def admin_attributes
    params.require(:admin).permit(:password, :password_confirmation)
  end

end