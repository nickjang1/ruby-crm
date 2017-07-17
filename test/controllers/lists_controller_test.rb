require 'test_helper'

describe ListsController do
  include Devise::TestHelpers

  describe "corporate" do
    let(:user){ create(:user, current_property_role: Role.corporate) }

    before do
      create_list(:list, 5)
      sign_in user
    end

    describe "GET#index" do
      it "corporate should have no list access" do
        get :index
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#new" do
      it "corporate should have no new access" do
        get :new
        assert_redirected_to authenticated_root_path
      end
    end

    describe "POST#create" do
      it "corporate should have no create access" do
        post :create, tag: {name: "NEW LIST"}
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#edit" do
      it "corporate should have no edit access" do
        get :edit, id: List.first.id
        assert_redirected_to authenticated_root_path
      end
    end

    describe "PUT#update" do
      it "corporate should have no put access" do
        put :update, list: {name: "NEW"}, id: List.first.id
        assert_redirected_to authenticated_root_path
      end
    end

    describe "DELETE#destroy" do
      it "corporate should have no delete access" do
        delete :destroy, id: List.first.id
        assert_redirected_to authenticated_root_path
      end
    end
  end

  describe "agm" do
    let(:user){ create(:user, current_property_role: Role.agm) }

    before do
      create_list(:list, 5)
      sign_in user
    end

    describe "GET#index" do
      it "agm should have list access" do
        get :index
        assert_response :success
      end
    end

    describe "GET#new" do
      it "agm should have new access" do
        get :new
        assert_response :success
      end
    end

    describe "POST#create" do
      it "agm should have create access" do
        post :create, tag: {name: "NEW LIST"}
        List.last.user_id.wont_be_nil
        assert_redirected_to lists_path
      end
    end

    describe "GET#edit" do
      it "agm should have edit access" do
        get :edit, id: List.first.id
        assert_response :success
      end
    end

    describe "PUT#update" do
      it "agm should have put access" do
        put :update, tag: {name: "NEW"}, id: List.first.id
        assert_redirected_to lists_path
      end
    end

    describe "DELETE#destroy" do
      it "agm should have delete access" do
        delete :destroy, id: List.first.id
        assert_redirected_to lists_path
      end
    end
  end

  describe "gm" do
    let(:user){ create(:user, current_property_role: Role.gm) }

    before do
      create_list(:list, 5)
      sign_in user
    end

    describe "GET#index" do
      it "gm should have list access" do
        get :index
        assert_response :success
      end
    end

    describe "GET#new" do
      it "gm should have new access" do
        get :new
        assert_response :success
      end
    end

    describe "POST#create" do
      it "agm should have create access" do
        post :create, tag: {name: "NEW LIST"}
        List.last.user_id.wont_be_nil
        assert_redirected_to lists_path
      end
    end

    describe "GET#edit" do
      it "gm should have edit access" do
        get :edit, id: List.first.id
        assert_response :success
      end
    end

    describe "PUT#update" do
      it "gm should have put access" do
        put :update, tag: {name: "NEW"}, id: List.first.id
        assert_redirected_to lists_path
      end
    end

    describe "DELETE#destroy" do
      it "gm should have delete access" do
        delete :destroy, id: List.first.id
        assert_redirected_to lists_path
      end
    end
  end

  describe "manager" do
    let(:user){ create(:user, current_property_role: Role.manager) }
    let(:non_managable_lists){ create_list(:list, 5) }
    let(:managable_lists){ create_list(:list, 2, user: user) }
    
    before do
      sign_in user
    end

    describe "GET#index" do
      it "manager can see only their own created lists" do
        non_managable_lists # call to let 'em be created
        managable_lists     # call to let 'em be created
        get :index
        assert_select '.widget', 2
      end
    end

    describe "GET#new" do
      it "manager should have new access" do
        get :new
        assert_response :success
      end
    end

    describe "POST#create" do
      it "manager should have create access" do
        post :create, tag: {name: "NEW LIST"}
        List.last.user_id.must_equal user.id
        assert_redirected_to lists_path
      end
    end

    describe "GET#edit" do
      it "manager should not have edit access for list that doesn't belong to him" do
        get :edit, id: non_managable_lists.first.id
        assert_redirected_to authenticated_root_path
      end

      it "manager should have edit access for list that belongs to him" do
        get :edit, id: managable_lists.first.id
        assert_response :success
      end
    end

    describe "PUT#update" do
      it "manager should not have update access for list that doesn't belong to him" do
        put :update, tag: {name: "NEW"}, id: non_managable_lists.first.id
        assert_redirected_to authenticated_root_path
      end

      it "manager should have update access for list that belongs to him" do
        put :update, tag: {name: "NEW"}, id: managable_lists.first.id
        assert_redirected_to lists_path
      end
    end

    describe "DELETE#destroy" do
      it "manager should not have delete access for list that doesn't belong to him" do
        delete :destroy, id: non_managable_lists.first.id
        assert_redirected_to authenticated_root_path
      end

      it "manager should have delete access for list that belongs to him" do
        delete :destroy, id: managable_lists.first.id
        assert_redirected_to lists_path
      end
    end

  end
end
