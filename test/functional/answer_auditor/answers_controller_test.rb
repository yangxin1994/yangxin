# encoding: utf-8
require 'test_helper'

class AnswerAuditor::AnswersControllerTest < ActionController::TestCase

	test "should list answers" do
		clear(User, Survey, Answer)
	
		jesse = init_jesse
		admin = init_admin
		answer_auditor = init_answer_auditor
		survey_auditor = init_survey_auditor
	
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		survey = Survey.find_by_id(survey_id)
	
		set_survey_published(survey_id, jesse, survey_auditor)


		answer_1 = Answer.create
		answer_1.status = 2
		survey.answers << answer_1

		answer_2 = Answer.create
		answer_2.status = 2
		survey.answers << answer_2

		auth_key = sign_in(answer_auditor.email, Encryption.decrypt_password(answer_auditor.password))
		get :index, :format => :json, :auth_key => auth_key, :survey_id => survey_id
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::SURVEY_NOT_EXIST, result["value"]["error_code"]
		sign_out(auth_key)

		survey.answer_auditors << answer_auditor

		auth_key = sign_in(answer_auditor.email, Encryption.decrypt_password(answer_auditor.password))
		get :index, :format => :json, :auth_key => auth_key, :survey_id => survey_id
		result = JSON.parse(@response.body)
		answer_list = result["value"]["data"]
		assert_equal 2, answer_list.length
		answer_id_list = answer_list.map { |e| e["_id"] }
		assert answer_id_list.include?(answer_1._id.to_s)
		assert answer_id_list.include?(answer_2._id.to_s)
		sign_out(auth_key)
	end

	test "should show answer" do
		clear(User, Survey, Answer)
	
		jesse = init_jesse
		admin = init_admin
		answer_auditor = init_answer_auditor
		survey_auditor = init_survey_auditor
	
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		survey = Survey.find_by_id(survey_id)
	
		set_survey_published(survey_id, jesse, survey_auditor)


		answer_1 = Answer.create
		answer_1.status = 2
		survey.answers << answer_1

		answer_2 = Answer.create
		answer_2.status = 2
		survey.answers << answer_2

		auth_key = sign_in(answer_auditor.email, Encryption.decrypt_password(answer_auditor.password))
		get :show, :format => :json, :auth_key => auth_key, :id => answer_1._id.to_s
		result = JSON.parse(@response.body)
		assert result["success"]
		assert_equal answer_1._id.to_s, result["value"]["_id"]
		sign_out(auth_key)
	end

	test "should review answer" do
		clear(User, Survey, Answer)
	
		jesse = init_jesse
		admin = init_admin
		answer_auditor = init_answer_auditor
		survey_auditor = init_survey_auditor
	
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		survey = Survey.find_by_id(survey_id)
	
		set_survey_published(survey_id, jesse, survey_auditor)


		# answer_1 is not finished
		answer_1 = Answer.create
		survey.answers << answer_1

		# answer_2 is finished
		answer_2 = Answer.create
		answer_2.status = 2
		survey.answers << answer_2

		auth_key = sign_in(answer_auditor.email, Encryption.decrypt_password(answer_auditor.password))
		post :review, :format => :json, :auth_key => auth_key, :id => answer_1._id.to_s, :review_result => 1
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::ANSWER_NOT_FINISHED, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(answer_auditor.email, Encryption.decrypt_password(answer_auditor.password))
		post :review, :format => :json, :auth_key => auth_key, :id => answer_2._id.to_s, :review_result => 1
		result = JSON.parse(@response.body)
		assert result["success"]
		assert result["value"]
		answer_2 = Answer.find_by_id(answer_2._id.to_s)
		assert_equal 1, answer_2.finish_type
		assert_equal answer_auditor._id.to_s, answer_2.auditor._id.to_s
		sign_out(auth_key)
	end
end
