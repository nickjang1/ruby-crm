require 'minitest/autorun'
require 'test_helper'

describe TagsController do
  include Devise::TestHelpers

  before do
    @user  = create(:user)
    @items = create_list(:item_with_vendor_item, 5, property: @user.properties.first)
    sign_in @user
    @t = create(:tag, type: 'Category')
  end

  it "should be able to create tags with some items" do
    post :create, tag: {name: "Supertag!", item_ids: @items.map(&:id)}

    assert (not @items.first.reload.tags.empty?), "Has tag for the item"
  end

  it 'denies access for unauthorized' do
    sign_out @user

    get :index
    assert_response :redirect
  end
  
  it 'edits the tag' do
    put :update, id: @t.id, tag: { name: Faker::Name.name }
    assert_response :redirect
  end

  it "doesn't save the tag when a required field is missing" do
    put :update, id: @t.id, tag: { name: '' }
    response.body.must_include "can't be blank"
  end

  it 'destroys the tag' do
    delete :destroy, id: @t.id
    assert_response :redirect
  end

end
