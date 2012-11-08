# encoding: utf-8
require 'test_helper'

class Admin::SurveysControllerTest < ActionController::TestCase

	test "should allocate system users" do
		clear(User, Survey)
	
		jesse = init_jesse
		admin = init_admin
		answer_auditor = init_answer_auditor
		survey_auditor = init_survey_auditor
		entry_clerk = init_entry_clerk
		interviewer = init_interviewer
	
		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		survey = Survey.find_by_id(survey_id)
	
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :allocate, :format => :json, :auth_key => auth_key, :id => survey_id, :user_id => answer_auditor._id.to_s, :system_user_type => "answer_auditor", :allocate => true
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::REQUIRE_ADMIN, result["value"]["error_code"]
		sign_out(auth_key)
	
		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		post :allocate, :format => :json, :auth_key => auth_key, :id => survey_id, :user_id => answer_auditor._id.to_s, :system_user_type => "wrong_system_user_type", :allocate => true
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::SYSTEM_USER_TYPE_ERROR, result["value"]["error_code"]
		sign_out(auth_key)
	
		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		post :allocate, :format => :json, :auth_key => auth_key, :id => survey_id, :user_id => "wrong user id", :system_user_type => "answer_auditor", :allocate => true
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::USER_NOT_EXIST, result["value"]["error_code"]
		sign_out(auth_key)
	
		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		post :allocate, :format => :json, :auth_key => auth_key, :id => survey_id, :user_id => survey_auditor._id.to_s, :system_user_type => "answer_auditor", :allocate => true
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::USER_NOT_EXIST, result["value"]["error_code"]
		sign_out(auth_key)
	
		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		post :allocate, :format => :json, :auth_key => auth_key, :id => survey_id, :user_id => answer_auditor._id.to_s, :system_user_type => "answer_auditor", :allocate => true
		result = JSON.parse(@response.body)
		assert result["success"]
		assert result["value"]
		answer_auditor = User.find_by_id(answer_auditor._id.to_s)
		assert_equal 1, answer_auditor.answer_auditor_allocated_surveys.length
		assert_equal survey_id, answer_auditor.answer_auditor_allocated_surveys[0]._id.to_s
		sign_out(auth_key)
	
		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		post :allocate, :format => :json, :auth_key => auth_key, :id => survey_id, :user_id => answer_auditor._id.to_s, :system_user_type => "answer_auditor", :allocate => false
		result = JSON.parse(@response.body)
		assert result["success"]
		assert result["value"]
		answer_auditor = User.find_by_id(answer_auditor._id.to_s)
		assert_equal 0, answer_auditor.answer_auditor_allocated_surveys.length
		sign_out(auth_key)
	end
end
