require 'test_helper'

describe Ability do
  it "corporate user can't view lists index" do
    u = FactoryGirl.create(:user, current_property_role: Role.corporate)
    ability = Ability.new(u)
    ability.cannot?(:index, List).must_equal true
  end

  it "gm user can view lists index" do
    u = FactoryGirl.create(:user, current_property_role: Role.gm)
    ability = Ability.new(u)
    ability.can?(:index, List).must_equal true
  end

  it "manager user cannot assign roles" do
    u = FactoryGirl.create(:user, current_property_role: Role.manager)
    ability = Ability.new(u)
    ability.can?(:manage_restricted_attributes, User).must_equal false
  end

  it "gm user can assign roles" do
    u = FactoryGirl.create(:user, current_property_role: Role.gm)
    ability = Ability.new(u)
    ability.can?(:manage_restricted_attributes, User).must_equal true
  end

end
