require 'spec_helper'

describe 'visit reward_schemes' do

	before(:all) do
		@auth_key = admin_signin
	end

	describe 'without survey exist' do 

		it "the /index of reward scheme should return SURVEY_NOT_EXIST" do
			get "/admin/surveys/1/reward_schemes", 
				auth_key: @auth_key
				response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /show of reward scheme should return SURVEY_NOT_EXIST" do
			get "/admin/surveys/1/reward_schemes/1", 
			auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /create of reward scheme should return SURVEY_NOT_EXIST" do
			post "/admin/surveys/1/reward_schemes", 
			auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /update of reward scheme should return SURVEY_NOT_EXIST" do
			put "/admin/surveys/1/reward_schemes/1", 
			auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /destroy of reward scheme should return SURVEY_NOT_EXIST" do
			delete "/admin/surveys/1/reward_schemes/1",
			auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

	end

	describe 'with survey exist' do
		before(:each) do
			@survey = FactoryGirl.create(:survey)
		end

		it "the /index of reward scheme should return [] while no reward_scheme message" do
			get "/admin/surveys/#{@survey.id}/reward_schemes",
			page: 1,
			per_page: 8,
			auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]  ##No message found,then should return a nil
			expect(retval["data"]).to eq([])
		end

		it "the /index of reward scheme should return 5 messages" do
			reward_list = FactoryGirl.create_list(:reward_scheme, 5) { |scheme| scheme.survey_id = @survey.id }
			RewardScheme.all.length.should be(5)
			get "/admin/surveys/#{@survey.id}/reward_schemes", 
			page: 1,
			per_page: 8,
			auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"].length
			expect(retval).to eq(5)
		end

		it "the /show of reward scheme should return reward_scheme details" do
			reward_scheme = FactoryGirl.create(:reward_scheme)
			scheme_in_db = RewardScheme.find_by_id(reward_scheme.id)
			get "/admin/surveys/#{@survey.id}/reward_schemes/#{reward_scheme.id}", 
				auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]
			expect(scheme_in_db.rewards).to eq(retval["rewards"]) ##just conpare the values
		end

		it "the /create of reward scheme should return true" do
			reward_scheme = FactoryGirl.build(:reward_scheme)
			RewardScheme.all.length.should be(0)
			post "/admin/surveys/#{@survey.id}/reward_schemes/", 
				reward_scheme_setting: {
					"rewards" => reward_scheme.rewards,
					"need_review" => reward_scheme.need_review
					},
				auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]
			expect(retval).to eq(true)
		end

		it "the /update of reward scheme should return true" do
			reward_scheme = FactoryGirl.create(:lottery_reward_scheme)
			rewards_in_db = reward_scheme.rewards
			new_deadline = Time.now.to_i.to_s
			rewards_in_db[0][:prizes][0][:deadline] = new_deadline
			put "/admin/surveys/#{@survey.id}/reward_schemes/#{reward_scheme.id}", 
				reward_scheme_setting: {
					"rewards" => rewards_in_db,
					"need_review" => true
					},
				auth_key: @auth_key
			response.status.should be(200)
			scheme_in_db = RewardScheme.find_by_id(reward_scheme.id)
			retval = JSON.parse(response.body)["value"]
			expect(retval).to eq(true)
			expect(scheme_in_db.need_review).to eq(true)
			expect(scheme_in_db.rewards[0]["prizes"][0]["deadline"]).to eq(new_deadline)
		end

		it "the /delete of reward scheme should return true" do
			reward_scheme = FactoryGirl.create_list(:reward_scheme, 10)
			RewardScheme.all.length.should be(10)
			delete_scheme = RewardScheme.all[0]
			delete "/admin/surveys/#{@survey.id}/reward_schemes/#{delete_scheme.id}", 
				auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]
			expect(retval).to eq(true)
			RewardScheme.all.length.should be(9)
			RewardScheme.find_by_id(delete_scheme.id).should be(nil)
		end

		after(:each) do
			clear(:Survey)
			clear(:RewardScheme)
		end
	end

	describe "verify respone message correct" do

		before(:each) do
			@survey = FactoryGirl.create(:survey)
		end

		it "/index should return 8 messages when set page 1 and per_page 8" do
			reward_list = FactoryGirl.create_list(:reward_scheme, 10)
			get "/admin/surveys/#{@survey.id}/reward_schemes",
			page: 1,
			per_page: 8,
			auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"].length
			expect(retval).to eq(8)
		end

		it "/index should return 3 messages when set page 2 and per_page 8" do
			reward_list = FactoryGirl.create_list(:reward_scheme, 10)
			get "/admin/surveys/#{@survey.id}/reward_schemes",
			page: 2,
			per_page: 8,
			auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"].length
			expect(retval).to eq(2)
		end

		it "/show should return REWARD_SCHEME_NOT_EXIST when reward_scheme id not found" do
			reward_scheme = FactoryGirl.create(:reward_scheme)
			scheme_in_db = RewardScheme.find_by_id(reward_scheme.id)
			get "/admin/surveys/#{@survey.id}/reward_schemes/#{reward_scheme.id.to_s.next}", 
			auth_key: @auth_key
			response.status.should be(200)
			retval = retval = JSON.parse(response.body)["value"]["error_code"]
			expect(ErrorEnum::REWARD_SCHEME_NOT_EXIST).to eq(retval)
		end

		after(:each) do
			clear(:Survey)
			clear(:RewardScheme)
		end

	end

end
