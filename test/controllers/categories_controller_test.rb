require 'minitest/autorun'
require 'test_helper'

describe CategoriesController do
  include Devise::TestHelpers

  let(:user){ create(:user) }
  let(:categories){ create_list(:category, 5, property: user.properties.first) }
  let(:prop2){ create(:property) }

  before do
    categories
    sign_in user
  end

  describe '#index' do
    before do
      user.user_roles << create(:user_role, role_id: Role.agm.id, property_id: prop2.id)
      create_list(:category, 3, property: prop2)
    end

    it 'should list items for the current property' do
      get :index
      assigns[:tags].length.must_equal 5
    end

    it 'should list items for the other property' do
      session[:property_id] = prop2.id
      get :index
      assert assigns[:tags].length == 3
    end
  end

  describe '#edit' do
    before do
      @prop2categories = create_list(:category, 3, property: prop2)
    end

    it 'should allow to edit category from owned property' do
      get :edit, id: user.properties.first.categories.unscoped.first.id
      assert_response :success
    end

    it 'should not allow to edit category not owned property' do
      proc {
        get :edit, id: @prop2categories.first.id
        assert_response :missing
        }.must_raise(ActiveRecord::RecordNotFound)
    end
  end

end
