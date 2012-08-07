# encoding: utf-8
require 'test_helper'

class SurveyAuditor::SurveysControllerTest < ActionController::TestCase
	test "should reject survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		survey_auditor = init_survey_auditor
		
		closed_survey_id = create_closed_survey(jesse)
		under_review_survey_id = create_under_review_survey(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :reject, :format => :json, :id => under_review_survey_id, :message => "you are rejected"
		assert_equal ErrorEnum::REQUIRE_SURVEY_AUDITOR.to_s, @response.body
		sign_out

		sign_in(survey_auditor.email, Encryption.decrypt_password(survey_auditor.password))
		get :reject, :format => :json, :id => closed_survey_id, :message => "you are rejected"
		assert_equal ErrorEnum::WRONG_PUBLISH_STATUS.to_s, @response.body
		sign_out

		sign_in(survey_auditor.email, Encryption.decrypt_password(survey_auditor.password))
		get :reject, :format => :json, :id => under_review_survey_id, :message => "you are rejected"
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => under_review_survey_id
		survey_obj = JSON.parse(@response.body)
		assert_equal PublishStatus::PAUSED, survey_obj["publish_status"]
		sign_out
	end

	test "should publish survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		survey_auditor = init_survey_auditor
		
		closed_survey_id = create_closed_survey(jesse)
		under_review_survey_id = create_under_review_survey(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :publish, :format => :json, :id => under_review_survey_id, :message => "you are publish"
		assert_equal ErrorEnum::REQUIRE_SURVEY_AUDITOR.to_s, @response.body
		sign_out

		sign_in(survey_auditor.email, Encryption.decrypt_password(survey_auditor.password))
		get :publish, :format => :json, :id => closed_survey_id, :message => "you are publish"
		assert_equal ErrorEnum::WRONG_PUBLISH_STATUS.to_s, @response.body
		sign_out

		sign_in(survey_auditor.email, Encryption.decrypt_password(survey_auditor.password))
		get :publish, :format => :json, :id => under_review_survey_id, :message => "you are publish"
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => under_review_survey_id
		survey_obj = JSON.parse(@response.body)
		assert_equal PublishStatus::PUBLISHED, survey_obj["publish_status"]
		sign_out
	end

	test "should close survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		survey_auditor = init_survey_auditor
		
		published_survey_id = create_published_survey(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :close, :format => :json, :id => published_survey_id
		assert_equal ErrorEnum::REQUIRE_SURVEY_AUDITOR.to_s, @response.body
		sign_out

		sign_in(survey_auditor.email, Encryption.decrypt_password(survey_auditor.password))
		get :close, :format => :json, :id => published_survey_id
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => published_survey_id
		survey_obj = JSON.parse(@response.body)
		assert_equal PublishStatus::CLOSED, survey_obj["publish_status"]
		sign_out
		
		sign_in(survey_auditor.email, Encryption.decrypt_password(survey_auditor.password))
		get :close, :format => :json, :id => published_survey_id
		assert_equal ErrorEnum::WRONG_PUBLISH_STATUS.to_s, @response.body
		sign_out
	end

	test "should pause survey" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver
		survey_auditor = init_survey_auditor
		
		published_survey_id = create_published_survey(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :pause, :format => :json, :id => published_survey_id
		assert_equal ErrorEnum::REQUIRE_SURVEY_AUDITOR.to_s, @response.body
		sign_out
		
		sign_in(survey_auditor.email, Encryption.decrypt_password(survey_auditor.password))
		get :pause, :format => :json, :id => published_survey_id
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :id => published_survey_id
		survey_obj = JSON.parse(@response.body)
		assert_equal PublishStatus::PAUSED, survey_obj["publish_status"]
		sign_out
		
		sign_in(survey_auditor.email, Encryption.decrypt_password(survey_auditor.password))
		get :pause, :format => :json, :id => published_survey_id
		assert_equal ErrorEnum::WRONG_PUBLISH_STATUS.to_s, @response.body
		sign_out
	end
end
