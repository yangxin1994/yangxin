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

	test "visitor user" do
		clear(User, Survey, Answer)
		jesse = init_jesse
		visitor_user_auth_key = create_new_visitor_user
		survey_auditor = init_survey_auditor
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		set_survey_published(survey_id, jesse, survey_auditor)

		# update access control setting to require a single password
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

		post :load_question, :format => :json, :auth_key => visitor_user_auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]

		a = Answer.first
		assert_equal visitor_user_auth_key, User.find_by_id(a.user_id).auth_key

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]
		sign_out(auth_key)

		assert_equal 1, Answer.all.length
		a = Answer.first
		assert_equal jesse._id.to_s, a.user._id.to_s

		post :load_question, :format => :json, :auth_key => visitor_user_auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::REQUIRE_LOGIN, result["value"]["error_code"]
	end

	test "should check channel quota" do
		clear(User, Survey, Answer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		polly = init_polly
		survey_auditor = init_survey_auditor

		# create survey and set the status of the survey as published
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		set_survey_published(survey_id, jesse, survey_auditor)

		# remove the default quota rule for the survey
		delete_quota_rule(jesse.email, jesse.password, survey_id, 0)

		# verify that there is no quota rules
		survey = Survey.find_by_id(survey_id)
		assert_equal 0, survey.quota_stats["answer_number"].length

		# insert a new quota rule to the survey
		quota_rule = {}
		quota_rule["amount"] = 2
		quota_rule["conditions"] = []
		quota_rule["conditions"] << {"condition_type" => 3, "name" => "channel", "value" => "1"}
		add_quota_rule(jesse.email, jesse.password, survey_id, quota_rule)

		# check the stats for the quota rule
		survey = Survey.find_by_id(survey_id)
		assert_equal 1, survey.quota_stats["answer_number"].length
		assert_equal 0, survey.quota_stats["answer_number"][0]

		# first answer
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]

		# check the stats for the quota rule after the first answer
		survey = Survey.find_by_id(survey_id)
		assert_equal 1, survey.quota_stats["answer_number"].length
		assert_equal 1, survey.quota_stats["answer_number"][0]

		# second answer
		auth_key = sign_in(lisa.email, Encryption.decrypt_password(lisa.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]

		# check the stats for the quota rule after the second answer
		survey = Survey.find_by_id(survey_id)
		assert_equal 1, survey.quota_stats["answer_number"].length
		assert_equal 2, survey.quota_stats["answer_number"][0]

		# third answer, violate the quotas, should be rejected
		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::VIOLATE_QUOTA, result["value"]["error_code"]

		# refreshe and check the stats for the quota rule
		survey = Survey.find_by_id(survey_id)
		assert_equal false, survey.quota_stats["quota_satisfied"]
		survey.refresh_quota_stats
		assert_equal true, survey.quota_stats["quota_satisfied"]

		# insert a new quota rule
		quota_rule = {}
		quota_rule["amount"] = 3
		quota_rule["conditions"] = []
		quota_rule["conditions"] << {"condition_type" => 4, "name" => "ip", "value" => "166.111.*.*"}
		add_quota_rule(jesse.email, jesse.password, survey_id, quota_rule)

		# check the stats for the quota rule after the new quota rule is inserted
		survey = Survey.find_by_id(survey_id)
		assert_equal false, survey.quota_stats["quota_satisfied"]
		assert_equal 2, survey.quota_stats["answer_number"][0]
		assert_equal 2, survey.quota_stats["answer_number"][1]

		# oliver's answering should be rejected since it violated quotas, though it should pass the quota now
		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 1, result["value"][0]
		assert_equal 0, result["value"][1]

		survey = Survey.find_by_id(survey_id)
		assert_equal false, survey.quota_stats["quota_satisfied"]
		assert_equal 2, survey.quota_stats["answer_number"][0]
		assert_equal 2, survey.quota_stats["answer_number"][1]

		# third answer
		auth_key = sign_in(polly.email, Encryption.decrypt_password(polly.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 2,
				:ip => "166.111.135.92"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]

		# check the quota stats
		survey = Survey.find_by_id(survey_id)
		assert_equal false, survey.quota_stats["quota_satisfied"]
		assert_equal 2, survey.quota_stats["answer_number"][0]
		assert_equal 3, survey.quota_stats["answer_number"][1]
		survey.refresh_quota_stats
		assert_equal true, survey.quota_stats["quota_satisfied"]
	end

	test "should initialize answer correctly" do
		clear(User, Survey, Answer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		polly = init_polly
		survey_auditor = init_survey_auditor

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		question_ids = pages.flatten

		set_survey_published(survey_id, jesse, survey_auditor)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert_equal 3, result["value"][0].length
		a = Answer.first
		assert_equal 10, a.answer_content.length
	end

	def add_quota_rule(email, password, survey_id, quota_rule)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuotasController.new
		post :create, :format => :json, :survey_id => survey_id, :quota_rule => quota_rule, :auth_key => auth_key
		@controller = old_controller
		sign_out(auth_key)
	end

	def delete_quota_rule(email, password, survey_id, quota_index)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuotasController.new
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 0, :auth_key => auth_key
		@controller = old_controller
		sign_out(auth_key)
	end

end
