class JoinInvitationsController < ApplicationController
  before_filter :authenticate_user!

  def accept
    invitation = JoinInvitation.find(params[:id])
    if invitation && current_user == invitation.invitee
      if invitation.target_type == 'hotel'
        invitation.targetable.run do
          user_params = ActionController::Parameters.new(invitation.params).permit!
          current_user.update(user_params)
          current_user.reload
        end
      elsif invitation.target_type == 'corporate'
        current_user.update_attributes(corporate_id: invitation.targetable_id)
        # invitation.targetable.properties.each do |p|
        #   p.run_block do
        #     current_user.current_property_role = Role.corporate
        #     current_user.title = 'Corporate User'
        #     current_user.order_approval_limit = 0
        #     current_user.departments << Department.find_or_create_by(name: 'All')
        #     current_user.save!
        #   end
        # end
      end
      redirect_to authenticated_root_path, notice: "You now have access to #{invitation.targetable.name}"
      invitation.destroy
    else
      redirect_to authenticated_root_path, alert: "Attempted to access an invitation they didn't own"
    end
  end

  def destroy
    invitation = JoinInvitation.find(params[:id])
    invitation.destroy
    redirect_to users_path
  end
end
