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
		assert_equal jesse.email, survey_obj["owner_email"]
		assert_equal "", survey_obj["survey_id"]
		assert_equal OOPSDATA["survey_default_settings"]["title"], survey_obj["title"]

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
		
		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		survey_obj["title"] = "修改未保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :survey => survey_obj
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改未保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :survey => survey_obj
		survey_obj = JSON.parse(@response.body)
		assert_equal "修改未保存在数据库中的调查问卷标题", survey_obj["title"]
		assert_not_equal "", survey_obj["survey_id"]
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :survey => survey_obj
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		non_exist_survey_obj = survey_obj.clone
		non_exist_survey_obj["survey_id"] = "wrong_survey_id"
		post :save_meta_data, :format => :json, :survey => non_exist_survey_obj
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :survey => survey_obj
		assert_equal "修改已经保存在数据库中的调查问卷标题", survey_obj["title"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => survey_obj["survey_id"]
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
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => "wrong_survey_id"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => survey_id
		survey_obj = JSON.parse(@response.body)
		assert_equal survey_id, survey_obj["survey_id"]
		sign_out
	end

	test "should delete survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :id => survey_id
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong_survey_id"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => survey_id
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
	end

	test "should recover survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		sign_out
		
		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :recover, :format => :json, :id => survey_id
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :recover, :format => :json, :id => "wrong_survey_id"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :recover, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => survey_id
		assert_not_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
	end

	test "should clear survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		sign_out
		
		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :clear, :format => :json, :id => survey_id
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clear, :format => :json, :id => "wrong_survey_id"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clear, :format => :json, :id => survey_id
		assert_equal true.to_s, @response.body
		get :list, :format => :json, :tags => ["已删除"]
		survey_obj_list = JSON.parse(@response.body)
		assert_equal 0, survey_obj_list.length
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
		post :save_meta_data, :format => :json, :survey => survey_obj
		survey_obj = JSON.parse(@response.body)
		sign_out
		return survey_obj["survey_id"]
	end
end
