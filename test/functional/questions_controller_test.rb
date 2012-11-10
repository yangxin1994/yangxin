require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase

	test "should create question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		insert_page(jesse.email, jesse.password, survey_id, -1, "first page")
		insert_page(jesse.email, jesse.password, survey_id, 0, "second page")

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => "wrong survey id", :page_index => 0, :question_id => -1, :question_type => 0, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => "wrong question id", :question_type => 0, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => 0, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => 200, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_QUESTION_TYPE.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => 0, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj_1 = result["value"]
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => 10, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj_3 = result["value"]
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => question_obj_1["_id"], :question_type => 12, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj_2 = result["value"]
		post :create, :format => :json, :survey_id => survey_id, :page_index => 1, :question_id => -1, :question_type => 15, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj_4 = result["value"]
		post :create, :format => :json, :survey_id => survey_id, :page_index => 1, :question_id => -1, :question_type => 13, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj_5 = result["value"]
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal 3, survey_obj["pages"][0]["questions"].length
		assert_equal 2, survey_obj["pages"][1]["questions"].length
		assert_equal question_obj_1["_id"], survey_obj["pages"][0]["questions"][0]
		assert_equal question_obj_2["_id"], survey_obj["pages"][0]["questions"][1]
		assert_equal question_obj_3["_id"], survey_obj["pages"][0]["questions"][2]
		assert_equal question_obj_4["_id"], survey_obj["pages"][1]["questions"][0]
		sign_out(auth_key)
	end

	test "should update question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)
		question_obj = get_question_obj(jesse.email, jesse.password, survey_id, pages[0][0])
		question_obj["issue"]["min_choice"] = 2
		question_obj["issue"]["max_choice"] = 4
		question_obj["issue"]["is_rand"] = true
		question_obj["issue"]["non_exist_attr"] = 1
		question_obj["issue"]["items"] << {"content" => "first choice content", "has_input" => false, "is_exclusive" => false, "non_exist_attr" => 1}

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => "wrong survey id", :id => pages[0][0], :question => question_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => "wrong question id", :question => question_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => pages[0][0], :question => question_obj, :auth_key => auth_key
		result = JSON.parse(@response.body)
		updated_question_obj = result["value"]
		sign_out(auth_key)
		assert_equal question_obj["issue"]["min_choice"], updated_question_obj["issue"]["min_choice"]
		assert_equal question_obj["issue"]["max_choice"], updated_question_obj["issue"]["max_choice"]
		assert_equal question_obj["issue"]["is_rand"], updated_question_obj["issue"]["is_rand"]
		assert_equal question_obj["issue"]["items"][0]["content"], updated_question_obj["issue"]["items"][0]["content"]
		assert_equal nil, updated_question_obj["issue"]["non_exist_attr"]
	end

	test "should show question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => "wrong survey id", :id => pages[0][1], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => survey_id, :id => "wrong question id", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => survey_id, :id => pages[0][1], :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj = result["value"]
		assert_equal pages[0][1], question_obj["_id"]
		sign_out(auth_key)
	end

	test "should delete question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => "wrong survey id", :id => pages[0][1], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => "wrong question id", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => pages[0][1], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		sign_out(auth_key)
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal pages.length, survey_obj["pages"].length
		assert_equal pages[0].length - 1, survey_obj["pages"][0]["questions"].length
		assert_equal pages[0][0], survey_obj["pages"][0]["questions"][0]
		assert_equal pages[0][2], survey_obj["pages"][0]["questions"][1]
	end	

	test "should move question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :move, :format => :json, :survey_id => "wrong survey id", :page_index => 2, :id => pages[2][1], :after_question_id => pages[2][3], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :move, :format => :json, :survey_id => survey_id, :page_index => 10, :id => pages[2][1], :after_question_id => pages[2][3], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::OVERFLOW.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :move, :format => :json, :survey_id => survey_id, :page_index => 2, :id => "wrong question id", :after_question_id => pages[2][3], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :move, :format => :json, :survey_id => survey_id, :page_index => 2, :id => pages[2][1], :after_question_id => pages[2][3], :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		sign_out(auth_key)
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal pages[2][0], survey_obj["pages"][2]["questions"][0]
		assert_equal pages[2][2], survey_obj["pages"][2]["questions"][1]
		assert_equal pages[2][3], survey_obj["pages"][2]["questions"][2]
		assert_equal pages[2][1], survey_obj["pages"][2]["questions"][3]

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :move, :format => :json, :survey_id => survey_id, :page_index => 2, :id => pages[2][1], :after_question_id => -1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		sign_out(auth_key)
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal pages[2][1], survey_obj["pages"][2]["questions"][0]
		assert_equal pages[2][0], survey_obj["pages"][2]["questions"][1]
		assert_equal pages[2][2], survey_obj["pages"][2]["questions"][2]
		assert_equal pages[2][3], survey_obj["pages"][2]["questions"][3]
	end

	test "should clone question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)
		question_obj = get_question_obj(jesse.email, jesse.password, survey_id, pages[0][0])
		question_obj["issue"]["min_choice"] = 2
		question_obj["issue"]["max_choice"] = 4
		question_obj["issue"]["is_rand"] = true
		question_obj["issue"]["items"] << {"content" => "first choice content", "has_input" => false, "is_exclusive" => false, "non_exist_attr" => 1}
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => pages[0][0], :question => question_obj, :auth_key => auth_key
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :clone, :format => :json, :survey_id => "wrong survey id", :page_index => 2, :id => pages[0][0], :after_question_id => -1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :clone, :format => :json, :survey_id => survey_id, :page_index => 10, :id => pages[0][0], :after_question_id => -1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::OVERFLOW.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :clone, :format => :json, :survey_id => survey_id, :page_index => 2, :id => "wrong question id", :after_question_id => -1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :clone, :format => :json, :survey_id => survey_id, :page_index => 2, :id => pages[0][0], :after_question_id => -1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		cloned_question_obj = result["value"]
		sign_out(auth_key)
		assert_equal question_obj["issue"]["min_choice"], cloned_question_obj["issue"]["min_choice"]
		assert_equal question_obj["issue"]["max_choice"], cloned_question_obj["issue"]["max_choice"]
		assert_equal question_obj["issue"]["is_rand"], cloned_question_obj["issue"]["is_rand"]
		assert_equal question_obj["issue"]["items"][0]["content"], cloned_question_obj["issue"]["items"][0]["content"]
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		cloned_question_obj = get_question_obj(jesse.email, jesse.password, survey_id, survey_obj["pages"][2]["questions"][0])
		assert_equal question_obj["issue"]["min_choice"], cloned_question_obj["issue"]["min_choice"]
		assert_equal question_obj["issue"]["max_choice"], cloned_question_obj["issue"]["max_choice"]
		assert_equal question_obj["issue"]["is_rand"], cloned_question_obj["issue"]["is_rand"]
		assert_equal question_obj["issue"]["items"][0]["content"], cloned_question_obj["issue"]["items"][0]["content"]
	end

	test "should insert template question" do
		clear(User, Survey, Question, TemplateQuestion)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa

		set_as_admin(lisa)

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		insert_page(jesse.email, jesse.password, survey_id, -1, "first page")
		insert_page(jesse.email, jesse.password, survey_id, 0, "second page")

		template_question_id = create_template_question(lisa.email, lisa.password, QuestionTypeEnum::CHOICE_QUESTION)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_template_question, :format => :json, :survey_id => "wrong survey id", :page_index => 0, :question_id => -1, :template_question_id => template_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_template_question, :format => :json, :survey_id => survey_id, :page_index => 3, :question_id => -1, :template_question_id => template_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::OVERFLOW.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_template_question, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => "wrong question id", :template_question_id => template_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :insert_template_question, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :template_question_id => template_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_template_question, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :template_question_id => "wron template question id", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::TEMPLATE_QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_template_question, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => 0, :template_question_id => template_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert result["value"]
		sign_out(auth_key)
	end

	test "should convert template question to normal question" do
		clear(User, Survey, Question, TemplateQuestion)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa

		set_as_admin(lisa)

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		insert_page(jesse.email, jesse.password, survey_id, -1, "first page")
		insert_page(jesse.email, jesse.password, survey_id, 0, "second page")

		template_question_id = create_template_question(lisa.email, lisa.password, QuestionTypeEnum::CHOICE_QUESTION)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_template_question, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => 0, :template_question_id => template_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj = result["value"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :convert_template_question_to_normal_question, :format => :json, :survey_id => survey_id, :id => "wrong question id", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		survey = Survey.find_by_id(survey_id)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :convert_template_question_to_normal_question, :format => :json, :survey_id => survey_id, :id => template_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		updated_question_obj = result["value"]
		survey = Survey.find_by_id(survey_id)

		get :show, :format => :json, :survey_id => survey_id, :id => updated_question_obj["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		normal_question = result["value"]
		assert_equal "Question", normal_question["type"]
		sign_out(auth_key)
	end

=begin
	test "should insert quality control question" do
		clear(User, Survey, Question, QualityControlQuestion, MatchingQuestion, QualityControlQuestionAnswer)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa

		set_as_admin(lisa)

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		insert_page(jesse.email, jesse.password, survey_id, -1, "first page")
		insert_page(jesse.email, jesse.password, survey_id, 0, "second page")

		objective_question_id = create_quality_control_question(lisa.email, lisa.password, QualityControlTypeEnum::OBJECTIVE, QuestionTypeEnum::CHOICE_QUESTION, -1)
		matching_question_id = create_quality_control_question(lisa.email, lisa.password, QualityControlTypeEnum::MATCHING, QuestionTypeEnum::CHOICE_QUESTION, 2)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_quality_control_question, :format => :json, :survey_id => "wrong survey id", :quality_control_question_id => objective_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		# manually insert quality control questions
		survey = Survey.find_by_id(survey_id)
		survey.quality_control_questions_type = 1
		survey.save

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :insert_quality_control_question, :format => :json, :survey_id => survey_id, :quality_control_question_id => objective_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_quality_control_question, :format => :json, :survey_id => survey_id, :quality_control_question_id => "wron quality control question id", :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_quality_control_question, :format => :json, :survey_id => survey_id, :quality_control_question_id => objective_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert result["value"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :insert_quality_control_question, :format => :json, :survey_id => survey_id, :quality_control_question_id => matching_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert result["value"]
		sign_out(auth_key)

		survey_obj = show_survey(jesse.email, jesse.password, survey_id)

		# delelete quality control question
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :delete_quality_control_question, :format => :json, :survey_id => survey_id, :id => objective_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		delete :delete_quality_control_question, :format => :json, :survey_id => survey_id, :id => matching_question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
	end
=end
end