require 'minitest/autorun'
require 'test_helper'

describe PropertiesController do
  include Devise::TestHelpers

  describe "manager" do
    before do
      sign_in create(:user, current_property_role: Role.manager)
    end

    describe "PUT#update" do
      it 'should not be able to update hotel settings' do
        put :update, id: Property.current_id
        assert_redirected_to authenticated_root_path
      end
    end
  end

  describe "gm" do
    before do
      sign_in create(:user, current_property_role: Role.gm)
    end

    describe "PUT#update" do
    end
  end

  describe "agm" do
    before do
      sign_in create(:user, current_property_role: Role.agm)
    end

    describe "PUT#update" do
      it 'should not be able to update hotel settings' do
        put :update, id: Property.current_id
        assert_redirected_to authenticated_root_path
      end
    end  
  end

  describe "corporate" do
    before do
      sign_in create(:user, current_property_role: Role.corporate)
    end

    describe "PUT#update" do
      it 'should not be able to update hotel settings' do
        put :update, id: Property.current_id
        assert_redirected_to authenticated_root_path
      end
    end  
  end

end
