require 'test_helper'

describe LocationsController do
  include Devise::TestHelpers

  describe "all users can manage locations" do
    let(:corporate){ create(:user, current_property_role: Role.corporate) }
    let(:agm){ create(:user, current_property_role: Role.agm) }
    let(:gm){ create(:user, current_property_role: Role.gm) }
    let(:manager){ create(:user, current_property_role: Role.manager) }

    before do
      create_list(:location, 5)
    end

    describe "corporate user" do
      before do
        sign_in corporate
      end

      it "corporate should have list access" do
        get :index
        assert_response :success
      end

      it "corporate should have new access" do
        get :new
        assert_response :success
      end

      it "corporate should have create access" do
        post :create, tag: {name: "NEW LOCATION"}
        Location.last.user_id.wont_be_nil
        assert_redirected_to locations_path
      end

      it "corporate should have edit access" do
        get :edit, id: Location.first.id
        assert_response :success
      end

      it "corporate should have put access" do
        put :update, tag: {name: "NEW"}, id: Location.first.id
        Location.first.name.must_equal "NEW"
        assert_redirected_to locations_path
      end

      it "corporate should have delete access" do
        delete :destroy, id: Location.first.id
        assert_redirected_to locations_path
      end
    end

    describe "agm user" do
      before do
        sign_in agm
      end

      it "agm should have list access" do
        get :index
        assert_response :success
      end

      it "agm should have new access" do
        get :new
        assert_response :success
      end

      it "agm should have create access" do
        post :create, tag: {name: "NEW LOCATION"}
        Location.last.user_id.wont_be_nil
        assert_redirected_to locations_path
      end

      it "agm should have edit access" do
        get :edit, id: Location.first.id
        assert_response :success
      end

      it "agm should have put access" do
        put :update, tag: {name: "NEW"}, id: Location.first.id
        Location.first.name.must_equal "NEW"
        assert_redirected_to locations_path
      end

      it "agm should have delete access" do
        delete :destroy, id: Location.first.id
        assert_redirected_to locations_path
      end
    end

    describe "gm user" do
      before do
        sign_in gm
      end

      it "gm should have list access" do
        get :index
        assert_response :success
      end

      it "gm should have new access" do
        get :new
        assert_response :success
      end

      it "gm should have create access" do
        post :create, tag: {name: "NEW LOCATION"}
        Location.last.user_id.wont_be_nil
        assert_redirected_to locations_path
      end

      it "gm should have edit access" do
        get :edit, id: Location.first.id
        assert_response :success
      end

      it "gm should have put access" do
        put :update, tag: {name: "NEW"}, id: Location.first.id
        Location.first.name.must_equal "NEW"
        assert_redirected_to locations_path
      end

      it "gm should have delete access" do
        delete :destroy, id: Location.first.id
        assert_redirected_to locations_path
      end
    end

    describe "manager user" do
      before do
        sign_in manager
      end

      it "manager should have list access" do
        get :index
        assert_response :success
      end

      it "manager should have new access" do
        get :new
        assert_response :success
      end

      it "manager should have create access" do
        post :create, tag: {name: "NEW LOCATION"}
        Location.last.user_id.wont_be_nil
        assert_redirected_to locations_path
      end

      it "manager should have edit access" do
        get :edit, id: Location.first.id
        assert_response :success
      end

      it "manager should have put access" do
        put :update, tag: {name: "NEW"}, id: Location.first.id
        Location.first.name.must_equal "NEW"
        assert_redirected_to locations_path
      end

      it "manager should have delete access" do
        delete :destroy, id: Location.first.id
        assert_redirected_to locations_path
      end
    end

  end
end
