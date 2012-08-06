# encoding: utf-8
require 'test_helper'

class SurveyAuditor::SurveysControllerTest < ActionController::TestCase
	test "should reject survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		survey_auditor = init_survey_auditor
		
		closed_survey_id = create_closed_survey
		under_review_survey_id = create_under_review_survey

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		get :reject, :format => :json, :id => under_review_survey_id, :message => "you are rejected"
		assert_equal ErrorEnum::REQUIRE_SURVEY_AUDITOR.to_s, @response.body
		sign_out

		sign_in(survey_auditor.email, Encryption.decrypt_password(oliver.password))
		get :reject, :format => :json, :id => closed_survey_id, :message => "you are rejected"
		assert_equal ErrorEnum::WRONG_PUBLISH_STATUS.to_s, @response.body
		sign_out

		sign_in(survey_auditor.email, Encryption.decrypt_password(oliver.password))
		get :reject, :format => :json, :id => under_review_survey_id, :message => "you are rejected"
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => under_review_survey_id
		survey_obj = JSON.parse(@response.body)
		assert_equal PublishStatus::PAUSED, survey_obj["publish_status"]
		sign_out
	end
end
