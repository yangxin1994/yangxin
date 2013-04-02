# encoding: utf-8
require 'test_helper'

class SurveysControllerTest < ActionController::TestCase
	test "should create new survey" do
		clear(User, Survey)
		jesse = init_jesse

		get :new, :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :new, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		assert_not_equal "", survey_obj["_id"]
		assert_not_equal "", survey_obj["title"]

		sign_out(auth_key)
	end


	test "should save meta data" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :new, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改未保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		assert_equal "修改未保存在数据库中的调查问卷标题", survey_obj["title"]
		assert_not_equal "", survey_obj["_id"]
		sign_out(auth_key)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		non_exist_survey_obj = survey_obj.clone
		non_exist_survey_obj["_id"] = "wrong_survey_id"
		post :save_meta_data, :format => :json, :id => non_exist_survey_obj["_id"], :survey => non_exist_survey_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		survey_obj["title"] = "修改已经保存在数据库中的调查问卷标题"
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		assert_equal "修改已经保存在数据库中的调查问卷标题", survey_obj["title"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => survey_obj["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		assert_equal "修改已经保存在数据库中的调查问卷标题", survey_obj["title"]
		sign_out(auth_key)
	end

	test "should update and show style setting" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show_style_setting, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		style_setting = result["value"]
		assert_equal "", style_setting["style_sheet_name"]
		assert style_setting["has_progress_bar"]
		assert style_setting["has_question_number"]
		assert !style_setting["allow_pageup"]
		sign_out(auth_key)

		style_setting["style_sheet_name"] = "style sheet name"
		style_setting["has_progress_bar"] = false
		style_setting["has_question_number"] = false
		style_setting["allow_pageup"] = true
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update_style_setting, :format => :json, :id => survey_id, :style_setting => style_setting, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show_style_setting, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		style_setting = result["value"]
		assert_equal "style sheet name", style_setting["style_sheet_name"]
		assert !style_setting["has_progress_bar"]
		assert !style_setting["has_question_number"]
		assert style_setting["allow_pageup"]
		sign_out(auth_key)
	end

	test "should update and show access control setting" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show_access_control_setting, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		access_control_setting = result["value"]
		assert_equal -1, access_control_setting["times_for_one_computer"]
		assert !access_control_setting["has_captcha"]
		sign_out(auth_key)

		access_control_setting["times_for_one_computer"] = 2
		access_control_setting["has_captcha"] = true
		access_control_setting["password_control"]["password_type"] = 2
		username_password_list = []
		username_password_list << {"content" => ["u1", "p1"], "used" => false}
		username_password_list << {"content" => ["u2", "p2"], "used" => false}
		username_password_list << {"content" => ["u3", "p3"], "used" => false}
		access_control_setting["password_control"]["username_password_list"] = username_password_list

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update_access_control_setting, :format => :json, :id => survey_id, :access_control_setting => access_control_setting, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show_access_control_setting, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		access_control_setting = result["value"]
		assert_equal 2, access_control_setting["times_for_one_computer"]
		assert access_control_setting["has_captcha"]
		assert_equal 2, access_control_setting["password_control"]["password_type"]
		assert_equal 3, access_control_setting["password_control"]["username_password_list"].length
		assert_equal "u2", access_control_setting["password_control"]["username_password_list"][1]["content"][0]
		assert !access_control_setting["password_control"]["username_password_list"][1]["used"]
		sign_out(auth_key)
	end

	test "should get survey object" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => "wrong_survey_id", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)
		

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		assert_equal survey_id, survey_obj["_id"]
		sign_out(auth_key)
	end

	test "should delete survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong_survey_id", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :index, :format => :json, :status => "deleted", :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 1, survey_obj_list.length
		assert_equal survey_id, survey_obj_list[0]["_id"]
		get :index, :format => :json, :status => "normal", :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 0, survey_obj_list.length
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :recover, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :index, :format => :json, :status => "normal", :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 1, survey_obj_list.length
		assert_equal survey_id, survey_obj_list[0]["_id"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :clear, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :index, :format => :json, :status => "all", :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 0, survey_obj_list.length
		sign_out(auth_key)
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

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :status => "normal", :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 5, survey_obj_list.length
		sign_out(auth_key)


		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => survey_id_1, :auth_key => auth_key
		delete :destroy, :format => :json, :id => survey_id_2, :auth_key => auth_key
		get :index, :format => :json, :status => "normal", :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 3, survey_obj_list.length
		get :index, :format => :json, :status => "deleted", :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 2, survey_obj_list.length
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :add_tag, :format => :json, :id => survey_id_1, :tag => "t1", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		put :add_tag, :format => :json, :id => survey_id_1, :tag => "t1", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::TAG_EXIST.to_s, result["value"]["error_code"]
		put :add_tag, :format => :json, :id => survey_id_2, :tag => "t1", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		put :add_tag, :format => :json, :id => survey_id_3, :tag => "t1", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :index, :format => :json, :status => "all", :tags => ["t1"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 3, survey_obj_list.length
		get :index, :format => :json, :status => "deleted", :tags => ["t1"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 2, survey_obj_list.length
		get :index, :format => :json, :status => "normal", :tags => ["t1"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 1, survey_obj_list.length
		put :remove_tag, :format => :json, :id => survey_id_3, :tag => "t1", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :index, :format => :json, :status => "all", :tags => ["t1"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj_list = result["value"]
		assert_equal 2, survey_obj_list.length
		sign_out(auth_key)
	end

	test "should clone survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :clone, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clone, :format => :json, :id => survey_id, :title => "new_title", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal "new_title", result["value"]["title"]
		sign_out(auth_key)
	end

	test "should submit survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :submit, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :submit, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :show, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		assert_equal QuillCommon::PublishStatusEnum::UNDER_REVIEW, survey_obj["publish_status"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :submit, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_PUBLISH_STATUS.to_s, result["value"]["error_code"]
		sign_out(auth_key)
	end

	test "should close survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		published_survey_id = create_published_survey(jesse)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :close, :format => :json, :id => published_survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :close, :format => :json, :id => published_survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :show, :format => :json, :id => published_survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		assert_equal QuillCommon::PublishStatusEnum::CLOSED, survey_obj["publish_status"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :close, :format => :json, :id => published_survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_PUBLISH_STATUS.to_s, result["value"]["error_code"]
		sign_out(auth_key)
	end

	test "should pause survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		
		published_survey_id = create_published_survey(jesse)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :pause, :format => :json, :id => published_survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :pause, :format => :json, :id => published_survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :show, :format => :json, :id => published_survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		assert_equal QuillCommon::PublishStatusEnum::PAUSED, survey_obj["publish_status"]
		sign_out(auth_key)
		
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :pause, :format => :json, :id => published_survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_PUBLISH_STATUS.to_s, result["value"]["error_code"]
		sign_out(auth_key)
	end
end
