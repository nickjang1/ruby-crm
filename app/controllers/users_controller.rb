class UsersController < ApplicationController
  add_breadcrumb I18n.t("controllers.users.team"), :users_path, :options => { :title => I18n.t("controllers.users.team") }
  before_filter :authenticate_user!
  respond_to :html, :json

  def user_params
    params.require(:user).permit :name, :title, :email, :username, :phone_number, :password, :password_confirmation, :avatar, :remove_avatar,
        :current_property_role_id, current_property_user_role_attributes: [:id, :role_id, :title, :order_approval_limit], department_ids: [], settings: [:work_order_group_by, :primary_hotel]
  end
  private :user_params

  def index
    authorize User
    target = current_user.corporate? ? current_user.corporate : Property.current
    @scope = params[:scope]
    if @scope == 'deleted'
      @user_roles = target.user_roles.only_deleted.order(:deleted_at)
    else
      @matching_users = target.users.active
      # @matching_users += current_property.corporate.users if current_property.corporate.present?
      @pending_invitations = target.join_invitations
    end

    respond_with @matching_users
  end

  def new
    @user = User.new
    authorize User, :new?
    @user.current_property_user_role = UserRole.new
    add_breadcrumb t("controllers.users.add_member")
    respond_with @user
  end

  def edit
    @user = User.with_deleted.find(params[:id])
    authorize @user
    add_breadcrumb t("controllers.users.user", name: @user.name)

    flash.now[:warning] = t('devise.failure.unconfirmed_admin') unless @user.confirmed?
    flash.now[:alert] = t("controllers.users.user_is_inactive") if @user.deleted?
  end

  def change_password
    edit
    add_breadcrumb t("controllers.users.change_password")
  end

  def valid_username
    @user = User.find_for_database_authentication({username: params[:username]})
    current_id = params[:user_id].to_i
    existing_user = @user && @user.id != current_id
    if existing_user && @user.all_properties.include?(Property.current)
      render json: {status: "not_valid", name: @user.name}
    elsif existing_user
      render json: {status: "confirm_code"}
    else
      render json: {status: "valid"}
    end
  end

  def confirm_username
    @user = User.find_for_database_authentication({username: params[:username]})
    if @user && @user.code == params[:code]
      render json: true
    else
      render json: false
    end
  end

  def create
    authorize User, :create?
    @user = User.new(user_params.merge(created_by_user: current_user))

    @user_by_username = user_params[:username].present?

    warden_condition = @user_by_username ? {username: user_params[:username]} : {email: user_params[:email]}
    if user = User.find_for_database_authentication(warden_condition)  # user with this email/username already exists
      if current_user.corporate?
        if user.corporate_id?
          flash.now[:error] = "A user with the #{warden_condition.keys.first} #{warden_condition[warden_condition.keys.first]} is already corporate user."
          render action: 'new'
        else
          if @user_by_username
            user.corporate_id = current_user.corporate.id if current_user.corporate?
            user.save
          else
            invitation = JoinInvitation.create(sender: current_user, invitee: user, targetable: current_user.corporate)
            Mailer.delay.join_invitation(invitation.id)
          end
          redirect_to users_path, notice: 'User was invited to join this corporate.'
        end
      else
        invite_params = user_params.slice 'current_property_user_role_attributes', 'department_ids', 'username'
        invite_params.delete_if { |k, v| v.blank? }

        if user.properties.include? current_property # they are already connected to this property
          flash.now[:error] = "A user with the email #{warden_condition.keys.first} #{warden_condition[warden_condition.keys.first]} already exists in this hotel."
          render action: 'new'
        else # user exists but isn't connected to this property so let's invite them
          if @user_by_username
            user.update(invite_params)
          else
            invitation = JoinInvitation.create(
              sender: current_user,
              invitee: user,
              targetable: current_property,
              params: invite_params
            )
            Mailer.delay.join_invitation(invitation.id)
          end
          redirect_to users_path, notice: 'User was invited to join this hotel.'
        end
      end
    else # create a new user
      if @user_by_username
        @user.skip_confirmation!
        @user.corporate_id = current_user.corporate.id if current_user.corporate?
      end
      if @user.save
        @user.confirm! if @user_by_username
        redirect_to users_path, notice: t("controllers.users.user_was_created")
      else
        render action: 'new'
      end
    end
  end

  def update
    restore = params["submit_button"] == "Activate"
    inactivate = params["submit_button"] == "Inactivate"

    @user = User.with_deleted.find(params[:id])
    authorize @user
    # TODO https://github.com/rails/rails/issues/6127
    settings = params[:user].delete :settings
    if settings
      @user.settings ||= {}
      @user.settings.merge! settings
      @user.settings_will_change!
      @user.save

      respond_with @user, location: policy(User).index? ? users_path : edit_user_path(@user) and return if params[:user].blank?
    end
    if params[:user][:password].blank?
      params[:user].delete :password
      params[:user].delete :password_confirmation
    end
    restore && @user.activate!
    if @user.update(user_params)
      inactivate && @user.inactivate!
      flash[:notice] = t("controllers.users.user_was_updated") unless request.xhr?
      respond_with @user, location: policy(User).index? ? users_path : edit_user_path(@user)
    else
      changing_password = params[:user][:password].present? && @user == current_user
      action = changing_password ? 'change_password' : 'edit'
      render action: action
    end
  end

  def destroy
    @user = User.find(params[:id])
    authorize @user
    @user.inactivate!
    redirect_to users_url, notice: t("controllers.users.user_was_inactivated")
  end

  private

  # @param [String, Symbol] scope_name The name of the scope desired.
  #   Defaults to 'current_property' if nil or not provided.
  #
  # @return [Hash{String => Hash}] A hash describing the scope.  Contains
  #   a :required_permission which provides the Permission symbol needed
  #   on User to view it, and a :users key which provides a proc which,
  #   when called, yields a Relation with the users for the scope.
  def index_scope(scope_name = nil)
    { 'all' => {required_permission: :manage, users: proc{User.all} },
      'deleted' => {required_permission: :manage, users: proc{User.only_deleted} },
      'active' => {required_permission: :read, users: proc{current_property.users.where.not(confirmed_at: nil) }},
      'current_property' => {required_permission: :read, users: proc{current_property.users} }
    }[(scope_name || 'current_property').to_s]
  end
end
