# encoding: utf-8
require 'test_helper'

class AnswersControllerTest < ActionController::TestCase

	test "should check password" do
		clear(User, Survey, Answer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		survey_auditor = init_survey_auditor

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		set_survey_published(survey_id, jesse, survey_auditor)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]
		sign_out(auth_key)

		# update access control setting to require a single password
		access_control_setting = {}
		access_control_setting["times_for_one_computer"] = 2
		access_control_setting["has_captcha"] = true
		access_control_setting["password_control"] = {}
		access_control_setting["password_control"]["password_type"] = 0
		access_control_setting["password_control"]["single_password"] = "abcd"
		update_survey_access_control_setting(jesse.email, Encryption.decrypt_password(jesse.password), survey_id, access_control_setting)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::WRONG_SURVEY_PASSWORD, result["value"]["error_code"]
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "abcd"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]
		sign_out(auth_key)

		# update access control setting to set a password list
		access_control_setting = {}
		access_control_setting["times_for_one_computer"] = 2
		access_control_setting["has_captcha"] = true
		access_control_setting["password_control"] = {}
		access_control_setting["password_control"]["password_type"] = 1
		password_list = []
		password_list << {"content" => "p1", "used" => false}
		password_list << {"content" => "p2", "used" => false}
		password_list << {"content" => "p3", "used" => false}
		access_control_setting["password_control"]["password_list"] = password_list
		update_survey_access_control_setting(jesse.email, Encryption.decrypt_password(jesse.password), survey_id, access_control_setting)

		clear(Answer)
		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "abcd"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::WRONG_SURVEY_PASSWORD, result["value"]["error_code"]
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]
		sign_out(auth_key)
		auth_key = sign_in(lisa.email, Encryption.decrypt_password(lisa.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::REQUIRE_LOGIN, result["value"]["error_code"]
		sign_out(auth_key)

		# update access control setting to set a username password list
		access_control_setting = {}
		access_control_setting["times_for_one_computer"] = 2
		access_control_setting["has_captcha"] = true
		access_control_setting["password_control"] = {}
		access_control_setting["password_control"]["password_type"] = 2
		username_password_list = []
		username_password_list << {"content" => ["u1", "p1"], "used" => false}
		username_password_list << {"content" => ["u2", "p2"], "used" => false}
		username_password_list << {"content" => ["u3", "p3"], "used" => false}
		access_control_setting["password_control"]["username_password_list"] = username_password_list
		update_survey_access_control_setting(jesse.email, Encryption.decrypt_password(jesse.password), survey_id, access_control_setting)

		clear(Answer)
		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::WRONG_SURVEY_PASSWORD, result["value"]["error_code"]
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :username => "u1", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]
		sign_out(auth_key)
		auth_key = sign_in(lisa.email, Encryption.decrypt_password(lisa.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :username => "u1", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::REQUIRE_LOGIN, result["value"]["error_code"]
		sign_out(auth_key)
	end
end
