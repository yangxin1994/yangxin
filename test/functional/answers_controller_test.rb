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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::WRONG_SURVEY_PASSWORD, result["value"]["error_code"]
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "abcd"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::WRONG_SURVEY_PASSWORD, result["value"]["error_code"]
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]
		sign_out(auth_key)
		auth_key = sign_in(lisa.email, Encryption.decrypt_password(lisa.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::SURVEY_PASSWORD_USED, result["value"]["error_code"]
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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::WRONG_SURVEY_PASSWORD, result["value"]["error_code"]
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :username => "u1", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]
		sign_out(auth_key)
		auth_key = sign_in(lisa.email, Encryption.decrypt_password(lisa.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :username => "u1", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::SURVEY_PASSWORD_USED, result["value"]["error_code"]
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

		post :load_question, :format => :json, :auth_key => visitor_user_auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0]

		a = Answer.first
		assert_equal visitor_user_auth_key, User.find_by_id(a.user_id).auth_key

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		sign_out(auth_key)

		post :load_question, :format => :json, :auth_key => visitor_user_auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :password => "p1"
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
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
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 2,
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
		clear(User, Survey, Question, Answer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		polly = init_polly
		survey_auditor = init_survey_auditor

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)
		question_ids = pages.flatten
		set_survey_published(survey_id, jesse, survey_auditor)

		# quetions loadding for surveys that do not allow page up
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		# the first has three questions
		assert_equal 3, result["value"][0].length
		# there are 10 questions totally
		a = Answer.first
		assert_equal 10, a.answer_content.length

		# update the style setting to make the survey allow page up
		style_setting = get_survey_style_setting(jesse.email, Encryption.decrypt_password(jesse.password), survey_id)
		style_setting["allow_pageup"] = true
		update_survey_style_setting(jesse.email, Encryption.decrypt_password(jesse.password), survey_id, style_setting)

		# questions loading for surveys that allow page up
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		# must provide question id when the survey allows page up
		assert_equal false, result["success"]
		assert_equal ErrorEnum::QUESTION_NOT_EXIST, result["value"]["error_code"]

		# load the three questions in the first page
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :question_id => -1, :next_page => true
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 3, result["value"][0].length
		assert_equal pages[0][0], result["value"][0][0]["_id"]
		assert_equal pages[0][1], result["value"][0][1]["_id"]
		assert_equal pages[0][2], result["value"][0][2]["_id"]

		# load the latter two questions in the first page
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :question_id => pages[0][0], :next_page => true
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0].length
		assert_equal pages[0][1], result["value"][0][0]["_id"]
		assert_equal pages[0][2], result["value"][0][1]["_id"]

		# load the questions in the third page
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :question_id => pages[1][-1], :next_page => true
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 4, result["value"][0].length
		assert_equal pages[2][0], result["value"][0][0]["_id"]
		assert_equal pages[2][1], result["value"][0][1]["_id"]
		assert_equal pages[2][2], result["value"][0][2]["_id"]
		assert_equal pages[2][3], result["value"][0][3]["_id"]
		
		# want to load the page after the last page, should return page overflow
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :question_id => pages[-1][-1], :next_page => true
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::OVERFLOW, result["value"]["error_code"]

		# want to load the page before the first page, should return page overflow
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :question_id => pages[0][0], :next_page => false
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]
		assert_equal ErrorEnum::OVERFLOW, result["value"]["error_code"]

		# load the first page questions
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :question_id => pages[1][0], :next_page => false
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal pages[0].length, result["value"][0].length
		assert_equal pages[0][0], result["value"][0][0]["_id"]
		assert_equal pages[0][1], result["value"][0][1]["_id"]

		# load the first two questions of the third page
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91", :question_id => pages[2][2], :next_page => false
		result = JSON.parse(@response.body)
		assert_equal true, result["success"]
		assert_equal 2, result["value"][0].length
		assert_equal pages[2][0], result["value"][0][0]["_id"]
		assert_equal pages[2][1], result["value"][0][1]["_id"]
	end

	test "should initialize answer with random quality control questions" do
		clear(User, Survey, Question, Answer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		polly = init_polly
		survey_auditor = init_survey_auditor

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)
		question_ids = pages.flatten
		set_survey_published(survey_id, jesse, survey_auditor)
		set_survey_random_quality_control_questions(survey_id)

		# quetions loadding for surveys that do not allow page up
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		a = Answer.first
		a.random_quality_control_locations.each do |key, value|
			assert question_ids.include?(key)
			assert a.random_quality_control_answer_content.has_key?(value)
		end
	end

	test "should submit answer correctly" do
		clear(User, Survey, Question, Answer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		polly = init_polly
		survey_auditor = init_survey_auditor

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)
		question_ids = pages.flatten
		set_survey_published(survey_id, jesse, survey_auditor)

		# quetions loadding for surveys that do not allow page up
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = "answer for the first question"
		answer_content[questions[1]["_id"]] = "answer for the second question"
		answer_content[questions[2]["_id"]] = "answer for the third question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		answer = Answer.first
		assert_equal "answer for the first question", answer.answer_content[questions[0]["_id"]]
		assert_equal "answer for the second question", answer.answer_content[questions[1]["_id"]]
		assert_equal "answer for the third question", answer.answer_content[questions[2]["_id"]]
		# load questions after answering the first three questions
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		assert_equal pages[1].length, questions.length
		assert_equal pages[1][0], questions[0]["_id"]
		# answer the questions in the second page
		answer_content = {}
		answer_content[questions[0]["_id"]] = "answer for the first question in the second page"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		answer = Answer.first
		assert_equal "answer for the first question in the second page", answer.answer_content[questions[0]["_id"]]
		# load questions in the third page
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		assert_equal pages[2].length, questions.length
		assert_equal pages[2][0], questions[0]["_id"]
		assert_equal pages[2][1], questions[1]["_id"]
		assert_equal pages[2][2], questions[2]["_id"]
		assert_equal pages[2][3], questions[3]["_id"]
		# answer the first three questions in the third page
		answer_content = {}
		answer_content[questions[0]["_id"]] = "answer for the first question in the third page"
		answer_content[questions[1]["_id"]] = "answer for the second question in the third page"
		answer_content[questions[2]["_id"]] = "answer for the third question in the third page"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		answer = Answer.first
		assert_equal "answer for the first question in the third page", answer.answer_content[questions[0]["_id"]]
		assert_equal "answer for the second question in the third page", answer.answer_content[questions[1]["_id"]]
		assert_equal "answer for the third question in the third page", answer.answer_content[questions[2]["_id"]]
		assert_equal nil, answer.answer_content[questions[3]["_id"]]
		# load questions again, the last question in the third page should be loaded
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		assert_equal 1, questions.length
		assert_equal pages[2][3], questions[0]["_id"]
		# answer the last question in the third page
		answer_content = {}
		answer_content[questions[0]["_id"]] = "answer for the fourth question in the third page"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		answer = Answer.first
		assert_equal "answer for the fourth question in the third page", answer.answer_content[questions[0]["_id"]]
		assert !answer.is_finish
		assert answer.is_edit
		# load questions in the last page
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		assert_equal pages[3].length, questions.length
		assert_equal pages[3][0], questions[0]["_id"]
		assert_equal pages[3][1], questions[1]["_id"]
		# answer the questions in the last page
		answer_content = {}
		answer_content[questions[0]["_id"]] = "answer for the first question in the last page"
		answer_content[questions[1]["_id"]] = "answer for the second question in the last page"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		answer = Answer.first
		assert_equal "answer for the first question in the last page", answer.answer_content[questions[0]["_id"]]
		assert_equal "answer for the second question in the last page", answer.answer_content[questions[1]["_id"]]
		# all the questions are answered, for the surveys that do not allow pageup, the answer process automatically finishes
		assert answer.is_finish
	end

	test "should check quality control when submitting answers" do
		clear(User, Survey, Question, QualityControlQuestion, QualityControlQuestionAnswer, Answer)
		jesse = init_jesse
		set_as_admin(jesse)
		oliver = init_oliver
		lisa = init_lisa
		polly = init_polly
		survey_auditor = init_survey_auditor

		# create the survey
		survey_id, pages = *create_short_survey_page_question(jesse.email, jesse.password)

		# insert a quality control question
		quality_control_question_id = create_objective_quality_control_question(jesse.email, jesse.password)
		insert_quality_control_question(jesse.email, jesse.password, survey_id, 0, 0, quality_control_question_id)

		# get questions ids of the survey after inserting quality control questions
		question_ids = Survey.find_by_id(survey_id).pages[0]["questions"]

		# set the survey published
		set_survey_published(survey_id, jesse, survey_auditor)

		# oliver answers the survey
		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [questions[0]["issue"]["items"][0]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the first normal question"
		answer_content[questions[2]["_id"]] = "answer for the second normal question"
		answer_content[questions[3]["_id"]] = "answer for the third normal question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		assert oliver.answers.first.is_finish
		assert_equal 1, Survey.find_by_id(survey_id).quota_stats["answer_number"][0]
		sign_out(auth_key)

		# lisa answers the survey
		auth_key = sign_in(lisa.email, Encryption.decrypt_password(lisa.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [questions[0]["issue"]["items"][1]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the first normal question"
		answer_content[questions[2]["_id"]] = "answer for the second normal question"
		answer_content[questions[3]["_id"]] = "answer for the third normal question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::VIOLATE_QUALITY_CONTROL_ONCE, result["value"]["error_code"]
		assert lisa.answers.first.is_redo
		assert_equal 1, Survey.find_by_id(survey_id).quota_stats["answer_number"][0]
		sign_out(auth_key)

		# lisa answers the survey the second time
		auth_key = sign_in(lisa.email, Encryption.decrypt_password(lisa.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		# the answer is in the status of redo
		assert_equal 3, result["value"][0]
		post :clear, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id
		result = JSON.parse(@response.body)
		assert result["success"]
		assert result["value"]
		assert lisa.answers.first.is_edit
		# load questions again
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [questions[0]["issue"]["items"][0]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the first normal question"
		answer_content[questions[2]["_id"]] = "answer for the second normal question"
		answer_content[questions[3]["_id"]] = "answer for the third normal question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		assert lisa.answers.first.is_finish
		assert_equal 2, Survey.find_by_id(survey_id).quota_stats["answer_number"][0]
		sign_out(auth_key)

		# polly answers the survey
		auth_key = sign_in(polly.email, Encryption.decrypt_password(polly.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [questions[0]["issue"]["items"][1]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the first normal question"
		answer_content[questions[2]["_id"]] = "answer for the second normal question"
		answer_content[questions[3]["_id"]] = "answer for the third normal question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		sign_out(auth_key)

		# polly answers the survey the second time
		auth_key = sign_in(polly.email, Encryption.decrypt_password(polly.password))
		post :clear, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id
		result = JSON.parse(@response.body)
		# load questions again
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [questions[0]["issue"]["items"][1]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the first normal question"
		answer_content[questions[2]["_id"]] = "answer for the second normal question"
		answer_content[questions[3]["_id"]] = "answer for the third normal question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::VIOLATE_QUALITY_CONTROL_TWICE, result["value"]["error_code"]
		assert polly.answers.first.is_reject
		assert_equal 2, Survey.find_by_id(survey_id).quota_stats["answer_number"][0]
		sign_out(auth_key)
	end

	test "should check remain answer time" do
		clear(User, Survey, Question, Answer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		polly = init_polly
		survey_auditor = init_survey_auditor

		survey_id, pages = *create_short_survey_page_question(jesse.email, jesse.password)
		question_ids = pages.flatten
		first_question = Question.find_by_id(question_ids[0])

		set_survey_published(survey_id, jesse, survey_auditor)

		# first user answers the survey
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :estimate_remain_answer_time, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id
		result = JSON.parse(@response.body)
		time_1 = result["value"]
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [first_question.issue["items"][0]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the second question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		get :estimate_remain_answer_time, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id
		result = JSON.parse(@response.body)
		time_2 = result["value"]
		assert time_1 > time_2
		sign_out(auth_key)
	end

	test "should check quota when submitting answers" do
		clear(User, Survey, Question, Answer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		polly = init_polly
		survey_auditor = init_survey_auditor

		survey_id, pages = *create_short_survey_page_question(jesse.email, jesse.password)
		question_ids = pages.flatten
		first_question = Question.find_by_id(question_ids[0])

		# remove the default quota rule for the survey
		delete_quota_rule(jesse.email, jesse.password, survey_id, 0)

		# add a question quota rule
		quota_rule = {}
		quota_rule["amount"] = 2
		quota_rule["conditions"] = []
		quota_rule["conditions"] << {"condition_type" => 1, "name" => question_ids[0], "value" => [first_question.issue["items"][0]["id"]], "fuzzy" => false}
		add_quota_rule(jesse.email, jesse.password, survey_id, quota_rule)

		set_survey_published(survey_id, jesse, survey_auditor)

		# first user answers the survey
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [first_question.issue["items"][0]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the second question"
		answer_content[questions[2]["_id"]] = "answer for the third question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		survey = Survey.find_by_id(survey_id)
		assert_equal 1, survey.quota_stats["answer_number"][0]
		assert jesse.answers.first.is_finish
		sign_out(auth_key)

		# second user answers the survey
		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [first_question.issue["items"][1]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the second question"
		answer_content[questions[2]["_id"]] = "answer for the third question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::VIOLATE_QUOTA, result["value"]["error_code"]
		survey = Survey.find_by_id(survey_id)
		assert_equal 1, survey.quota_stats["answer_number"][0]
		assert oliver.answers.first.is_reject
		sign_out(auth_key)

		# third user answers the survey
		auth_key = sign_in(lisa.email, Encryption.decrypt_password(lisa.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		questions = result["value"][0]
		# answer the questions in the first page
		answer_content = {}
		answer_content[questions[0]["_id"]] = {"selection" => [first_question.issue["items"][0]["id"]]}
		answer_content[questions[1]["_id"]] = "answer for the second question"
		answer_content[questions[2]["_id"]] = "answer for the third question"
		post :submit_answer, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :answer_content => answer_content
		result = JSON.parse(@response.body)
		assert result["success"]
		survey = Survey.find_by_id(survey_id)
		assert_equal 2, survey.quota_stats["answer_number"][0]
		assert lisa.answers.first.is_finish
		sign_out(auth_key)

		# fourth user answers the survey
		auth_key = sign_in(polly.email, Encryption.decrypt_password(polly.password))
		post :load_question, :format => :json, :auth_key => auth_key, :is_preview => false, :survey_id => survey_id, :channel => 1,
				:ip => "166.111.135.91"
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::VIOLATE_QUOTA, result["value"]["error_code"]
		survey = Survey.find_by_id(survey_id)
		assert polly.answers.first.is_reject
		sign_out(auth_key)
	end

	def insert_quality_control_question(email, password, survey_id, page_index, question_id, quality_control_question_id)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuestionsController.new
		post :insert_quality_control_question, :format => :json, :survey_id => survey_id, :page_index => page_index, :question_id => question_id, :quality_control_question_id => quality_control_question_id, :auth_key => auth_key
		@controller = old_controller
		sign_out(auth_key)
	end

	def create_objective_quality_control_question(email, password)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = Admin::QualityControlQuestionsController.new
		post :create, :format => :json, :quality_control_type => 1, :question_type => 0, :question_number => -1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		quality_control_question = result["value"][0]
		quality_control_question_answer = result["value"][1]
		answer_content = quality_control_question_answer["answer_content"]
		answer_content["items"] << quality_control_question["issue"]["items"][0]["id"]
		put :update_answer, :format => :json, :id => quality_control_question["_id"], :quality_control_type => 1, :answer => answer_content, :auth_key => auth_key
		@controller = old_controller
		sign_out(auth_key)
		return quality_control_question["_id"]
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
