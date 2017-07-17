require "test_helper"

describe User do
  before do
    @property = create(:property)
    @property.switch!
    @user = create(:user, current_property_role: Role.gm)
    @property1 = create(:property)
    @property1.switch!
    @user.user_roles << create(:user_role, role: Role.gm)
  end

  describe '#inactivate!' do
    it "should soft delete only current property's role" do
      @property.switch!
      @user.inactivate!
      @user.user_roles.with_deleted.where(property_id: @property.id).first.deleted_at.wont_be_nil
      @user.user_roles.empty?.must_equal false

      @user.all_properties.count.must_equal 1

      email = @user.email
      @property1.switch!
      @user.inactivate!

      @user.reload
      @user.email.must_equal 'inactive_' + email
      @user.deleted_at.wont_be_nil
    end
  end

  describe "#username" do
    before(:each) do
      @property.switch!
    end

    it "should allow enter username or email" do
      user = build(:user, current_property_role: Role.gm, email: nil, username: nil)
      user.valid?.must_equal false
    end

    it "should not allow email format" do
      user = build(:user, current_property_role: Role.gm, email: nil, username: Faker::Internet.email)
      user.valid?.must_equal false
    end

    it "should allow numbers, letters, underscore and punctuation" do
      user = build(:user, current_property_role: Role.gm, email: nil, username: Faker::Internet.user_name)
      user.valid?.must_equal true
    end

    it "should allow both email and username" do
      user = build(:user, current_property_role: Role.gm, username: Faker::Internet.user_name)
      user.valid?.must_equal true
    end

    it "should allow uniq username" do
      username = Faker::Internet.user_name
      user1 = create(:user, current_property_role: Role.gm, username: username)
      user2 = build(:user, current_property_role: Role.gm, username: username)
      user2.valid?.must_equal false
    end
  end
end