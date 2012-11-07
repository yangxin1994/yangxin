# encoding: utf-8
require 'test_helper'

class AnswerAuditor::SurveysControllerTest < ActionController::TestCase

	test "should list surveys" do
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
		get :index, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal 0, result["value"].length
		sign_out(auth_key)

		survey.answer_auditors << answer_auditor

		auth_key = sign_in(answer_auditor.email, Encryption.decrypt_password(answer_auditor.password))
		get :index, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal 1, result["value"].length
		sign_out(auth_key)
	end
end
