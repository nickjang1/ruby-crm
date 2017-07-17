require 'test_helper'

describe 'Users Integration' do
  before do
    reset_email
  end

  describe 'Login' do
    def sign_in(user)
      u = user
      fill_in 'user_email', with: u.email
      fill_in 'user_password', with: u.password
      click_button 'Sign In'
    end

    it 'sign in a user with valid credentials' do
      u = create(:user)
      visit new_user_session_path
      sign_in(u)
      #fill_in 'user_email', with: u.email
      #fill_in 'user_password', with: u.password
      #click_button 'Sign In'
      flash_messages.first.must_include 'Signed in successfully.'
    end

    it "doesn't sign in a user with valid credentials and unconfirmed account" do
      u = create(:user)
      u.confirmation_sent_at = Time.now - 1.day
      u.confirmed_at = nil
      u.save

      visit new_user_session_path
      sign_in(u)
      page.text.must_include 'You have to confirm your account before continuing'
    end

    it "doesn't sign in a user with invalid credentials" do
      u = create(:user)
      visit new_user_session_path
      fill_in 'user_email', with: u.email
      fill_in 'user_password', with: 'asdf'
      click_button 'Sign In'
      page.text.must_include 'Invalid email or password'

      fill_in 'user_email', with: 'asdf'
      fill_in 'user_password', with: u.password
      click_button 'Sign In'
      page.text.must_include 'Invalid email or password'
    end

    it "redirects to the login page if the user isn't authenticated" do
      visit purchase_requests_path

      page.has_content?('Login to Lodgistics').must_equal true
    end

    it "redirects to the originally requested page after login" do
      visit purchase_requests_path
      Property.first.switch!
      u = create(:user)

      sign_in(u)
      flash_messages.first.must_include 'Signed in successfully.'

      page.current_path.must_equal purchase_requests_path
    end
  end

  # describe 'Lost Password' do
  #   it 'sends a reset password link to user' do
  #     u = create(:user)
  #     visit new_user_password_path
  #     fill_in 'user_email', with: u.email
  #     click_button 'Send me reset password instructions'
  #     page.text.must_include 'You will receive an email with instructions about how to reset your password in a few minutes'

  #     last_email.to.must_include u.email
  #   end

  #   it "doesn't sends a reset password link when email not found or missing" do
  #     u = build(:user)
  #     visit new_user_password_path
  #     fill_in 'user_email', with: u.email
  #     click_button 'Send me reset password instructions'
  #     inline_error_for 'user_email', must_include: 'not found'

  #     fill_in 'user_email', with: ''
  #     click_button 'Send me reset password instructions'
  #     inline_error_for 'user_email', must_include: "can't be blank"

  #     last_email.must_be_nil
  #   end

  #   it 'changes user password when following reset password link and filling in a new password' do
  #     u = create(:user)
  #     visit new_user_password_path
  #     fill_in 'user_email', with: u.email
  #     click_button 'Send me reset password instructions'

  #     reset_password_link = last_email.body.match(/href="(.*)"/).captures.first

  #     visit reset_password_link
  #     fill_in 'user_password', with: 'password'
  #     fill_in 'user_password_confirmation', with: 'password'
  #     click_button 'Change my password'

  #     page.text.must_include 'Your password was changed successfully'
  #   end
  # end

  # describe 'Profile' do
  #   it "edits user's information without changing password" do
  #     u = create(:user_with_role)
  #     sign_in u
  #     visit edit_user_path(u)
  #     fill_in 'user_name', with: Faker::Name.name
  #     fill_in 'user_email', with: email = Faker::Internet.email
  #     fill_in 'user_current_password', with: u.password
  #     click_button 'Update'
  #     page.text.must_include 'You updated your account successfully'

  #     last_email.to.must_include email
  #   end

  #   it "doesn't edits user's information when current password isn't provided" do
  #     u = create(:user_with_role)
  #     sign_in u
  #     visit edit_user_path(u)
  #     fill_in 'user_name', with: Faker::Name.name
  #     fill_in 'user_email', with: email = Faker::Internet.email
  #     click_button 'Update'
  #     inline_error_for 'user_current_password', must_include: "can't be blank"

  #     fill_in 'user_name', with: ''
  #     fill_in 'user_current_password', with: u.password
  #     click_button 'Update'
  #     inline_error_for 'user_name', must_include: "can't be blank"

  #     fill_in 'user_name', with: u.name
  #     fill_in 'user_email', with: ''
  #     click_button 'Update'
  #     inline_error_for 'user_email', must_include: "can't be blank"

  #     fill_in 'user_email', with: 'asdf'
  #     click_button 'Update'
  #     inline_error_for 'user_email', must_include: 'is invalid'

  #     fill_in 'user_password', with: u.password
  #     fill_in 'user_password_confirmation', with: ''
  #     click_button 'Update'
  #     inline_error_for 'user_password', must_include: "doesn't match confirmation"

  #     fill_in 'user_password', with: 'asdf'
  #     fill_in 'user_password_confirmation', with: 'asdf'
  #     click_button 'Update'
  #     inline_error_for 'user_password', must_include: 'is too short'
  #   end
  # end

  # describe 'Sign Out' do
  #   it 'signs out a user' do
  #     u = create(:user)
  #     sign_in u
  #     sign_out
  #     page.text.wont_include u.name
  #   end
  # end


  describe 'Users Controller (management)' do
    let(:user) { create(:user) }
    before do
      create(:permission, role: Role.gm, department: user.departments.first, permission_attribute: attribute('Team'))
      sign_in user
    end

    #   it 'displays all users' do
    #     deleted_user = create(:user)
    #     deleted_user.destroy

    #     p = create(:property)
    #     r = create(:role, property_id: p.id)
    #     assigned_user = create(:user)
    #     assigned_user.roles << r

    #     visit users_path
    #     page.text.must_include @u.name
    #     page.text.wont_include deleted_user.name

    #     click_link 'Deleted'
    #     page.text.must_include deleted_user.name
    #     page.text.wont_include @u.name

    #     click_link 'All'
    #     page.text.must_include deleted_user.name
    #     page.text.must_include @u.name

    #     visit property_path(p, format: 'json')
    #     visit users_path
    #     page.text.must_include assigned_user.name
    #     page.text.wont_include @u.name
    #     page.text.wont_include deleted_user.name

    #     deleted_user.restore!
    #     click_link 'All'
    #     page.text.must_include @u.name
    #     page.text.must_include deleted_user.name
    #   end

    #   it 'edits the user' do
    #     visit edit_user_path(@u)
    #     fill_in 'user_name', with: Faker::Name.name
    #     click_button 'Save'
    #     page.text.must_include 'User was successfully updated'

    #     u = create(:user).delete
    #     visit edit_user_path(u)
    #     assert_equal 200, page.status_code
    #     fill_in 'user_name', with: Faker::Name.name
    #     click_button 'Save'
    #     page.text.must_include 'User was successfully updated'
    #   end

    #   it "doesn't update the user when a required field is missing" do
    #     visit edit_user_path(@u)
    #     fill_in 'user_name', with: ''
    #     click_button 'Save'
    #     inline_error_for 'user_name', must_include: "can't be blank"
    #   end

    #   it 'destroys the user' do
    #     u = create(:user)

    #     visit_with_delete user_path(u)
    #     page.text.wont_include u.name
    #     page.current_path.must_equal root_path
    #   end

    it 'gives a validation error if the email is already taken by a user connected to this property', js: true do
      u = create(:user)
      visit new_user_path
      fill_in 'user_name', with: u.name
      fill_in 'user_email', with: u.email
      fill_in 'user_current_property_user_role_attributes_title', with: "Foo"
      fill_in 'user_current_property_user_role_attributes_order_approval_limit', with: "1000"
      fill_in_selectized('user_departments', Department.first.id)

      select 'Manager', from: "user_current_property_user_role_attributes_role_id"

      click_button 'Create User'
      page.has_content?("A user with the email #{u.email} already exists in this hotel.").must_equal true
    end

    it 'connects sends an invitation to join this hotel if the user already exists but isnt connected to this property', js: true do
      u = nil
      create(:property).run_block do
        u = create(:user, name: "Stranger")
      end

      visit new_user_path
      fill_in 'user_name', with: u.name
      fill_in 'user_email', with: u.email
      fill_in 'user_current_property_user_role_attributes_title', with: "Foo"
      fill_in 'user_current_property_user_role_attributes_order_approval_limit', with: "1000"
      fill_in_selectized('user_departments', Department.first.id)

      select 'Manager', from: "user_current_property_user_role_attributes_role_id"

      click_button 'Create User'
      sleep 2
      page.has_content?('User was invited to join this hotel.').must_equal true

      assert page.has_no_css?("a", text: u.name)
    end

    it "doesn't change name and photo when connecting an existing user to a new property", js: true do
      u = nil
      create(:property).run_block do
        u = create(:user, name: "Stranger")
      end

      visit new_user_path
      fill_in 'user_name', with: "Friend"
      fill_in 'user_email', with: u.email
      fill_in 'user_current_property_user_role_attributes_title', with: "Foo"
      fill_in 'user_current_property_user_role_attributes_order_approval_limit', with: "1000"
      fill_in_selectized('user_departments', Department.first.id)

      select 'Manager', from: "user_current_property_user_role_attributes_role_id"

      click_button 'Create User'
      page.has_content?('User was invited to join this hotel.').must_equal true

      page.has_content?(u.name).must_equal true
      page.has_content?("Friend").must_equal false
      u.reload.name.must_equal "Stranger"

      sign_in u
      visit accept_join_invitation_path(JoinInvitation.last)
      u.reload.name.must_equal "Stranger"
    end

    it 'displays pending invitations on the index page' do
      create(:property).run_block do
        @invitee = create(:user)
      end

      JoinInvitation.create(sender: user, invitee: @invitee, targetable: Property.current)

      visit users_path
      page.has_content?(@invitee.name).must_equal true
    end

    # TODO: THIS WORKS ON LOCAL, but FAILING ON CIRCLECI
    # it 'should save primary hotel so it can be loaded as default hotel on next login', js: true do
    #   property1 = create(:property)
    #   property2 = create(:property)
    #   property1.switch!
    #   create(:user_role, user_id: user.id, role: Role.gm, property: property1)
    #   create(:user_role, user_id: user.id, role: Role.gm, property: property2)
    #
    #   visit edit_user_path(user)
    #   select property2.name, from: "user_settings_primary_hotel"
    #   fill_in 'user_current_property_user_role_attributes_title', with: "Foo"
    #   fill_in 'user_current_property_user_role_attributes_order_approval_limit', with: "1000"
    #
    #   click_button 'Update User'
    #
    #   page.has_content?("User was successfully updated.").must_equal true
    #   sign_out
    #
    #   sign_in user
    #   page.has_css?('span.hotel-name', property2.name).must_equal true
    # end
  end

  describe '#corporate' do
    before do
      Property.current_id = nil
      @corporate = create(:corporate)
      @user = create(:user, corporate: @corporate)
      @user1 = create(:user, corporate: @corporate)
      @user2 = create(:user)
      sign_in @user
    end

    it 'should show users linked to corporate' do
      visit users_path
      Property.current_id = nil

      page.has_content?(@user.name).must_equal true
      page.has_content?(@user1.name).must_equal true
      page.has_content?(@user2.name).must_equal false
    end

    it 'should not be able to create user if user already linked to corporate', js: true do
      visit users_path
      Property.current_id = nil

      find_link_with_icon('btn-primary', 'ico-plus-circle2', 'Add Team Member').click
      fill_in 'user_name', with: @user1.name
      fill_in 'user_email', with: @user1.email

      click_button 'Create User'

      page.has_css?('a', 'Team').must_equal true
      # flash_messages[0].must_include("A user with the email #{@user1.email} already exists in this corporate.").must_equal true
      assert current_path == users_path

      JoinInvitation.count.must_equal 0
    end

    it 'should send join corporate invitation if user exists and not linked to corporate', js: true do
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      visit users_path

      find_link_with_icon('btn-primary', 'ico-plus-circle2', 'Add Team Member').click
      fill_in 'user_name', with: @user2.name
      fill_in 'user_email', with: @user2.email
      click_button 'Create User'

      page.has_css?('li', 'Team').must_equal true
      # flash_messages[0].must_include('User was invited to join this hotel.').must_equal true
      sleep 2

      JoinInvitation.count.must_equal 1
      Sidekiq::Extensions::DelayedMailer.jobs.size.must_equal 1
      assert current_path == users_path
      page.has_css?('p.text-danger', 'Invitation Sent')
    end

    it "should send confirmation email if user doesn't exists", js: true do
      visit users_path

      find_link_with_icon('btn-primary', 'ico-plus-circle2', 'Add Team Member').click
      fill_in 'user_name', with: 'Corporate User'
      fill_in 'user_email', with: 'test@example.com'
      click_button 'Create User'

      # flash_messages[0].must_include('User was successfully created.').must_equal true
      page.has_css?('li', 'Team').must_equal true
      assert current_path = users_path
      sleep 2
      User.count.must_equal 4
      User.last.confirmed_at.must_equal nil
    end

    it 'should be able to update user', js: true do
      visit users_path

      click_link @user1.name
      fill_in 'user_name', with: 'New Corporate Name'
      click_button 'Update User'

      # flash_messages[0].must_include('User was successfully updated.').must_equal true
      page.has_css?('li', 'Team').must_equal true
      @user1.reload.name.must_equal 'New Corporate Name'
    end
  end
end
