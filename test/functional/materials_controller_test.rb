require 'test_helper'

class MaterialsControllerTest < ActionController::TestCase

	test "should create material" do
		clear(User, Material)
		jesse = init_jesse

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :material => {"material_type" => 3, "location" => "location", "title" => "title"}
		assert_equal ErrorEnum::WRONG_MATERIAL_TYPE.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :material => {"material_type" => 4, "location" => "location", "title" => "title"}
		material_obj = JSON.parse(@response.body)
		assert_equal jesse.email, material_obj["owner_email"]
		assert_equal 4, material_obj["material_type"]
		assert_equal "location", material_obj["location"]
		assert_equal "title", material_obj["title"]
		sign_out

	end

	test "should list materials" do
		clear(User, Material)
		jesse = init_jesse
		material_id_1, material_id_2, material_id_3, material_id_4, material_id_5, material_id_6 = *create_materials(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :material_type => 8
		assert_equal ErrorEnum::WRONG_MATERIAL_TYPE.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :material_type => 7
		material_obj_list = JSON.parse(@response.body)
		assert_equal 6, material_obj_list.length
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_1)
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_2)
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_3)
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_4)
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_5)
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_6)
		get :index, :format => :json, :material_type => 5
		material_obj_list = JSON.parse(@response.body)
		assert_equal 4, material_obj_list.length
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_1)
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_2)
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_3)
		assert material_obj_list.map{ |material_obj| material_obj["material_id"] }.include?(material_id_6)
		sign_out
	end

	test "should show material" do
		clear(User, Material)
		jesse = init_jesse
		oliver = init_oliver
		material_id_1, material_id_2, material_id_3, material_id_4, material_id_5, material_id_6 = *create_materials(jesse.email, jesse.password)

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :show, :format => :json, :id => material_id_1
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => "wrong_material_id"
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => material_id_1
		material_obj = JSON.parse(@response.body)
		assert_equal "location_1", material_obj["location"]
		assert_equal 1, material_obj["material_type"]
		assert_equal "title_1", material_obj["title"]
		sign_out
	end

	test "should delete material" do
		clear(User, Material)
		jesse = init_jesse
		oliver = init_oliver
		material_id_1, material_id_2, material_id_3, material_id_4, material_id_5, material_id_6 = *create_materials(jesse.email, jesse.password)

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :id => material_id_1
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong_material_id"
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => material_id_1
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => material_id_1
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST.to_s, @response.body
		sign_out
	end

	test "should update material" do
		clear(User, Material)
		jesse = init_jesse
		oliver = init_oliver
		material_id_1, material_id_2, material_id_3, material_id_4, material_id_5, material_id_6 = *create_materials(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => material_id_1
		material_obj = JSON.parse(@response.body)
		material_obj["title"] ="new title"
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :id => material_id_1
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong_material_id"
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => material_id_1, :material => material_obj
		material_obj = JSON.parse(@response.body)
		assert_equal "new title", material_obj["title"]
		get :show, :format => :json, :id => material_id_1
		material_obj = JSON.parse(@response.body)
		assert_equal "new title", material_obj["title"]
		sign_out
	end
end
