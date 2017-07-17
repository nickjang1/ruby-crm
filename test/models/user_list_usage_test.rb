require 'test_helper'

describe UserListUsage do
  before do
    Property.current_id = Property.first.id
    @user_list_usage = UserListUsage.new
  end

  it "must be valid" do
    @user_list_usage.list = create(:list)
    @user_list_usage.user = create(:user)
    @user_list_usage.valid?.must_equal true
  end
end
