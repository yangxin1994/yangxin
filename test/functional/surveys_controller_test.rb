# encoding: utf-8
require 'test_helper'

class SurveysControllerTest < ActionController::TestCase
	test "should create new survey" do
		clear(User, Survey)
		jesse = init_jesse

		get :new, :format => :json
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, @response.body
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :new, :format => :json
		survey_obj = JSON.parse(@response.body)
		assert_not_equal "", survey_obj["_id"]
		assert_not_equal "", survey_obj["title"]

		sign_out
	end


	test "should save meta data" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :new, :format => :json
		survey_obj = JSON.parse(@response.body)
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改未保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj
		survey_obj = JSON.parse(@response.body)
		assert_equal "修改未保存在数据库中的调查问卷标题", survey_obj["title"]
		assert_not_equal "", survey_obj["_id"]
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		non_exist_survey_obj = survey_obj.clone
		non_exist_survey_obj["_id"] = "wrong_survey_id"
		post :save_meta_data, :format => :json, :id => non_exist_survey_obj["_id"], :survey => non_exist_survey_obj
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj
		assert_equal "修改已经保存在数据库中的调查问卷标题", survey_obj["title"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => survey_obj["_id"]
		survey_obj = JSON.parse(@response.body)
		assert_equal "修改已经保存在数据库中的调查问卷标题", survey_obj["title"]
		sign_out
	end

	test "should get survey object" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :show, :format => :json, :id => survey_id
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => "wrong_survey_id"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => survey_id
		survey_obj = JSON.parse(@response.body)
		assert_equal survey_id, survey_obj["_id"]
		sign_out
	end

	test "should delete survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :id => survey_id
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong_survey_id"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		get :index, :format => :json, :status => "deleted"
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 1, survey_obj_list.length
		assert_equal survey_id, survey_obj_list[0]["_id"]
		get :index, :format => :json, :status => "normal"
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 0, survey_obj_list.length
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :recover, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		get :index, :format => :json, :status => "normal"
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 1, survey_obj_list.length
		assert_equal survey_id, survey_obj_list[0]["_id"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		get :clear, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		get :index, :format => :json, :status => "all"
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 0, survey_obj_list.length
		sign_out
	end

	test "should return survey object list" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id_1 = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_id_2 = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_id_3 = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_id_4 = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_id_5 = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :status => "normal"
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 5, survey_obj_list.length
		sign_out


		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id_1
		delete :destroy, :format => :json, :id => survey_id_2
		get :index, :format => :json, :status => "normal"
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 3, survey_obj_list.length
		get :index, :format => :json, :status => "deleted"
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 2, survey_obj_list.length
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :add_tag, :format => :json, :id => survey_id_1, :tag => "t1"
		assert_equal true.to_s, @response.body
		put :add_tag, :format => :json, :id => survey_id_1, :tag => "t1"
		assert_equal ErrorEnum::TAG_EXIST.to_s, @response.body
		put :add_tag, :format => :json, :id => survey_id_2, :tag => "t1"
		assert_equal true.to_s, @response.body
		put :add_tag, :format => :json, :id => survey_id_3, :tag => "t1"
		assert_equal true.to_s, @response.body
		get :index, :format => :json, :status => "all", :tags => ["t1"]
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 3, survey_obj_list.length
		get :index, :format => :json, :status => "deleted", :tags => ["t1"]
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 2, survey_obj_list.length
		get :index, :format => :json, :status => "normal", :tags => ["t1"]
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 1, survey_obj_list.length
		put :remove_tag, :format => :json, :id => survey_id_3, :tag => "t1"
		assert_equal true.to_s, @response.body
		get :index, :format => :json, :status => "all", :tags => ["t1"]
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 2, survey_obj_list.length
		sign_out
	end

	test "should clone survey" do
		#########################
		#########################
		#########################
		#########################
		#########################
		#########################
		#########################
		#########################
	end




	def create_survey(email, password)
		sign_in(email, password)
		get :new, :format => :json
		survey_obj = JSON.parse(@response.body)
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj
		survey_obj = JSON.parse(@response.body)
		sign_out
		return survey_obj["_id"]
	end
end
