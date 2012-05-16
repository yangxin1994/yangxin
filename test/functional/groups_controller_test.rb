require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
	test "should create group" do
		clear(User, Group)
		jesse = init_jesse
		members = generate_group_members

		post :create, :format => :json, :group => {"name" => "group_name", "description" => "group description", "members" => members}
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, @response.body

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :group => {"name" => "group name", "description" => "group description", "members" => members}
		group_obj = JSON.parse(@response.body)
		assert_equal "group name", group_obj["name"]
		assert_equal "group description", group_obj["description"]
		assert_equal members[0], group_obj["members"][0]
		assert_not_equal "", group_obj["group_id"].to_s
		sign_out
	end

	test "should update group" do
		clear(User, Group)
		jesse = init_jesse
		oliver = init_oliver
		members = generate_group_members

		group_obj = create_group(jesse.email, jesse.password, "group name", "group description", members)
		group_obj["name"] = "updated group name"
		group_obj["description"] = "updated group description"
		group_obj["members"] << "test@test.com"

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		put :update, :format => :json, :id => group_obj["group_id"], :group => group_obj
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => "wrong group id", :group => group_obj
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => group_obj["group_id"], :group => group_obj
		group_obj = JSON.parse(@response.body)
		assert_equal "updated group name", group_obj["name"]
		assert_equal "updated group description", group_obj["description"]
		assert_equal "test@test.com", group_obj["members"][-1]
		sign_out
	end

	test "should delete group" do
		clear(User, Group)
		jesse = init_jesse
		oliver = init_oliver
		members = generate_group_members

		group_obj = create_group(jesse.email, jesse.password, "group name", "group description", members)

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :id => group_obj["group_id"]
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong group id"
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => group_obj["group_id"]
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => group_obj["group_id"]
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, @response.body
		sign_out
	end

	test "should show group" do
		clear(User, Group)
		jesse = init_jesse
		oliver = init_oliver
		members = generate_group_members

		group_obj = create_group(jesse.email, jesse.password, "group name", "group description", members)

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :show, :format => :json, :id => group_obj["group_id"]
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => "wrong group id"
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => group_obj["group_id"]
		group_obj = JSON.parse(@response.body)
		assert_equal "group name", group_obj["name"]
		assert_equal "group description", group_obj["description"]
		assert_equal members[0], group_obj["members"][0]
		sign_out
	end

	test "should show groups" do
		clear(User, Group)
		jesse = init_jesse
		oliver = init_oliver
		members = generate_group_members

		create_group(jesse.email, jesse.password, "first name", "first description", members)
		create_group(jesse.email, jesse.password, "second name", "second description", [])
		create_group(jesse.email, jesse.password, "third name", "third description", ["test@test.com"])

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json
		group_obj_ary = JSON.parse(@response.body)
		assert_equal 3, group_obj_ary.length
		assert_equal "first name", group_obj_ary[0]["name"]
		assert_equal "second name", group_obj_ary[1]["name"]
		assert_equal "third name", group_obj_ary[2]["name"]
		assert_equal "first description", group_obj_ary[0]["description"]
		assert_equal "second description", group_obj_ary[1]["description"]
		assert_equal "third description", group_obj_ary[2]["description"]
		assert_equal members.length, group_obj_ary[0]["members"].length
		assert_equal 0, group_obj_ary[1]["members"].length
		assert_equal 1, group_obj_ary[2]["members"].length
		sign_out
	end
end
