require 'spec_helper'

describe 'visit surveys' do

	before(:all) do
		@auth_key = admin_signin
	end

	describe 'without survey exist' do

		# it "the /index of one survey should return []" do
		# 	get "/admin/surveys", 
		#     	auth_key: @auth_key
		# 	response.status.should be(200)
		# 	retval = JSON.parse(response.body)["value"]["data"]
		# 	expect(retval).to eq([])
		# end

		it "the /show of one survey should return SURVEY_NOT_EXIST" do
			get "/admin/surveys/1", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /promote of surveys should return SURVEY_NOT_EXIST" do
			get "/admin/surveys/1/promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /quillme_promote of survey should return SURVEY_NOT_EXIST" do
			post "/admin/surveys/1/quillme_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /email_promote of survey should return SURVEY_NOT_EXIST" do
			post "/admin/surveys/1/email_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /sms_promote of survey should return SURVEY_NOT_EXIST" do
			post "/admin/surveys/1/sms_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /broswer_extension_promote of survey should return SURVEY_NOT_EXIST" do
			post "/admin/surveys/1/broswer_extension_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /weibo_promote of survey should return SURVEY_NOT_EXIST" do
			post "/admin/surveys/1/weibo_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /background_survey of survey should return SURVEY_NOT_EXIST" do
			put "/admin/surveys/1/background_survey", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end
		
	end

	describe "with survey exist" do

		before(:each) do
			@survey = FactoryGirl.create(:survey)
			@creator = FactoryGirl.create(:survey_creator)
			@creator.surveys << @survey
		end

		it "the /index should return a right value" do
			get "/admin/surveys", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(1)
		end

	end

	after(:each) do
		clear(:Survey)
		clear(:RewardScheme)
		clear(:Prize)
	end
end
