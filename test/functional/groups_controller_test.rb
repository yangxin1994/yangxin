require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
	test "should create group" do
		clear(User, Group)
		jesse = init_jesse

		members = generate_group_members

		post :create, :format => :json, :group => {"name" => "group name", "description" => "group description", "members" => members}
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :group => {"name" => "group name", "description" => "group description", "members" => Marshal.load(Marshal.dump(members)) << {}}
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::ILLEGAL_EMAIL.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :group => {"name" => "group name", "description" => "group description", "members" => members}
		result = JSON.parse(@response.body)
		group_obj = result["value"]
		assert_not_equal "", group_obj["_id"].to_s
		assert_equal "group name", group_obj["name"]
		assert_equal "group description", group_obj["description"]
		assert_equal members[0]["email"], group_obj["members"][0]["email"]
		assert_equal members[0]["mobile"], group_obj["members"][0]["mobile"]
		assert_equal members[-1]["email"], group_obj["members"][-1]["email"]
		assert_equal members[-1]["mobile"], group_obj["members"][-1]["mobile"]
		get :show, :format => :json, :id => group_obj["_id"]
		result = JSON.parse(@response.body)
		group_obj = result["value"]
		assert_not_equal "", group_obj["_id"].to_s
		assert_equal "group name", group_obj["name"]
		assert_equal "group description", group_obj["description"]
		assert_equal members[0]["email"], group_obj["members"][0]["email"]
		assert_equal members[0]["mobile"], group_obj["members"][0]["mobile"]
		assert_equal members[-1]["email"], group_obj["members"][-1]["email"]
		assert_equal members[-1]["mobile"], group_obj["members"][-1]["mobile"]
		sign_out
	end

	test "should update group" do
		clear(User, Group)

		jesse = init_jesse
		oliver = init_oliver

		members = generate_group_members

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :group => {"name" => "group name", "description" => "group description", "members" => members}
		result = JSON.parse(@response.body)
		group_obj = result["value"]
		sign_out

		group_obj["name"] = "updated group name"
		group_obj["description"] = "updated group description"
		group_obj["members"] << {"email" => "new@member.com"}

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		put :update, :format => :json, :id => group_obj["_id"], :group => group_obj
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => "wrong group id", :group => group_obj
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => group_obj["_id"], :group => group_obj
		result = JSON.parse(@response.body)
		group_obj = result["value"]
		assert_equal "updated group name", group_obj["name"]
		assert_equal "updated group description", group_obj["description"]
		assert_equal "new@member.com", group_obj["members"][-1]["email"]
		get :show, :format => :json, :id => group_obj["_id"]
		result = JSON.parse(@response.body)
		group_obj = result["value"]
		assert_equal "updated group name", group_obj["name"]
		assert_equal "updated group description", group_obj["description"]
		assert_equal "new@member.com", group_obj["members"][-1]["email"]
		sign_out
	end

	test "should delete group" do
		clear(User, Group)

		jesse = init_jesse
		oliver = init_oliver
		
		members = generate_group_members


		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :group => {"name" => "group name", "description" => "group description", "members" => members}
		result = JSON.parse(@response.body)
		group_obj = result["value"]
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :id => group_obj["_id"]
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong group id"
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => group_obj["_id"]
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :show, :format => :json, :id => group_obj["_id"]
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out
	end

	test "should show group" do
		clear(User, Group)

		jesse = init_jesse
		oliver = init_oliver

		members = generate_group_members


		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :group => {"name" => "group name", "description" => "group description", "members" => members}
		result = JSON.parse(@response.body)
		group_obj = result["value"]
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :show, :format => :json, :id => group_obj["_id"]
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => "wrong group id"
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::GROUP_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => group_obj["_id"]
		result = JSON.parse(@response.body)
		group_obj = result["value"]
		assert_not_equal "", group_obj["_id"].to_s
		assert_equal "group name", group_obj["name"]
		assert_equal "group description", group_obj["description"]
		assert_equal members[0]["email"], group_obj["members"][0]["email"]
		assert_equal members[0]["mobile"], group_obj["members"][0]["mobile"]
		assert_equal members[-1]["email"], group_obj["members"][-1]["email"]
		assert_equal members[-1]["mobile"], group_obj["members"][-1]["mobile"]
		sign_out
	end

	test "should show groups" do
		clear(User, Group)
	
		jesse = init_jesse
		oliver = init_oliver

		members = generate_group_members

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :group => {"name" => "first name", "description" => "first description", "members" => members}
		result = JSON.parse(@response.body)
		group_id_1 = result["value"]["_id"]
		post :create, :format => :json, :group => {"name" => "second name", "description" => "second description", "members" => Marshal.load(Marshal.dump(members)) << {"email" => "new_1@new.com"}}
		result = JSON.parse(@response.body)
		group_id_2 = result["value"]["_id"]
		post :create, :format => :json, :group => {"name" => "third name", "description" => "third description", "members" => members}
		result = JSON.parse(@response.body)
		group_id_3 = result["value"]["_id"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json
		result = JSON.parse(@response.body)
		group_obj_ary = result["value"]
		assert_equal 3, group_obj_ary.length
		sign_out
	end
end
