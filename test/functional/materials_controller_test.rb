require 'test_helper'

class MaterialsControllerTest < ActionController::TestCase
	test "should create material" do
		clear(User, Material)
		jesse = init_jesse

		post :create, :format => :json, :material => {"title" => "first image material", "value" => "value of first image material", "material_type" => 1}
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :material => {"title" => "first image material", "value" => "value of first image material", "material_type" => 3}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_MATERIAL_TYPE.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :material => {"title" => "first image material", "value" => "value of first image material", "material_type" => 1}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj = result["value"]
		assert_not_equal "", material_obj["_id"].to_s
		assert_equal "first image material", material_obj["title"]
		assert_equal "value of first image material", material_obj["value"]
		assert_equal 1, material_obj["material_type"]
		get :show, :format => :json, :id => material_obj["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj = result["value"]
		assert_not_equal "", material_obj["_id"].to_s
		assert_equal "first image material", material_obj["title"]
		assert_equal "value of first image material", material_obj["value"]
		assert_equal 1, material_obj["material_type"]
		sign_out(auth_key)
	end

	test "should update material" do
		clear(User, Material)

		jesse = init_jesse
		oliver = init_oliver

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :material => {"title" => "first image material", "value" => "value of first image material", "material_type" => 1}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj = result["value"]
		sign_out(auth_key)

		material_obj["title"] = "new title"
		material_obj["value"] = "new value"

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		put :update, :format => :json, :id => material_obj["_id"], :material => material_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => "wrong material id", :material => material_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => material_obj["_id"], :material => material_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj = result["value"]
		assert_equal "new title", material_obj["title"]
		assert_equal "new value", material_obj["value"]
		assert_equal 1, material_obj["material_type"]
		get :show, :format => :json, :id => material_obj["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj = result["value"]
		assert_equal "new title", material_obj["title"]
		assert_equal "new value", material_obj["value"]
		assert_equal 1, material_obj["material_type"]
		sign_out(auth_key)
	end

	test "should delete material" do
		clear(User, Material)

		jesse = init_jesse
		oliver = init_oliver
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :material => {"title" => "first image material", "value" => "value of first image material", "material_type" => 1}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj = result["value"]
		sign_out(auth_key)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :id => material_obj["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert result["value"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong material id", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert result["value"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => material_obj["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :show, :format => :json, :id => material_obj["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)
	end


	test "should show materials" do
		clear(User, Group)
	
		jesse = init_jesse
		oliver = init_oliver

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :material => {"title" => "first image material", "value" => "value of first image material", "material_type" => 1}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_1 = result["value"]["_id"]
		post :create, :format => :json, :material => {"title" => "second image material", "value" => "value of second image material", "material_type" => 1}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_2 = result["value"]["_id"]
		post :create, :format => :json, :material => {"title" => "first video material", "value" => "value of first video material", "material_type" => 2}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_3 = result["value"]["_id"]
		post :create, :format => :json, :material => {"title" => "first audio material", "value" => "value of first audio material", "material_type" => 4}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_4 = result["value"]["_id"]
		sign_out(auth_key)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :material => {"title" => "first oliver's image material", "value" => "value of first oliver's image material", "material_type" => 1}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_5 = result["value"]["_id"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :material_type => 1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj_ary = result["value"]
		assert_equal 2, material_obj_ary.length
		assert_equal material_id_1, material_obj_ary[0]["_id"]
		assert_equal material_id_2, material_obj_ary[1]["_id"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :material_type => 3, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj_ary = result["value"]
		assert_equal 3, material_obj_ary.length
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :material_type => 7, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_obj_ary = result["value"]
		assert_equal 4, material_obj_ary.length
		sign_out(auth_key)
	end
end
