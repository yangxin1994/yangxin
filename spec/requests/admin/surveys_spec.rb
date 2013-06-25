require 'spec_helper'

describe 'visit surveys' do

	before(:all) do
		@auth_key = admin_signin
	end

	describe 'without survey exist' do

		it "the /index of one survey should return []" do
			get "/admin/surveys", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval).to eq([])
		end

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
			put "/admin/surveys/1/quillme_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /email_promote of survey should return SURVEY_NOT_EXIST" do
			put "/admin/surveys/1/email_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /sms_promote of survey should return SURVEY_NOT_EXIST" do
			put "/admin/surveys/1/sms_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /broswer_extension_promote of survey should return SURVEY_NOT_EXIST" do
			put "/admin/surveys/1/broswer_extension_promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["error_code"]
			expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
		end

		it "the /weibo_promote of survey should return SURVEY_NOT_EXIST" do
			put "/admin/surveys/1/weibo_promote", 
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
			FactoryGirl.create_list(:survey, 8) { |s| @creator.surveys << s }
			get "/admin/surveys", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			s = Survey.where("id" => retval[0]["id"]).first
			expect(retval.length).to eq(9)
			retval[0].each do |k, v|
				if (k == "email" or k == "mobile")
					expect(v).to eq(s.user.send(k).to_s)
				elsif k == "created_at"
					expect(v).to eq(s.send(k).to_i)
				else
					expect(v).to eq(s.send(k).to_s)
				end
			end
		end

		it "the /show of one survey should return survey detail" do
			get "/admin/surveys/#{@survey.id}", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]
			survey = Survey.where("id" => @survey.id).first.attributes
			survey['created_at'] = survey['created_at'].to_i
			survey['updated_at'] = survey['updated_at'].to_i
			retval.each do |k, v|
				expect(survey[k].to_s).to eq(v.to_s)
			end
		end

		it "the /promote of surveys should return true" do
			promote = {}
			promote['quillme'] = @survey.quillme_promote
			promote['email'] = @survey.email_promote
			promote['sms'] = @survey.sms_promote
			promote['broswer_extension'] = @survey.broswer_extension_promote
			promote['weibo'] = @survey.weibo_promote
			get "/admin/surveys/#{@survey.id}/promote", 
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]
			expect(retval).to eq(promote)
		end

		it "the /background_survey of survey should return true" do
			put "/admin/surveys/#{@survey.id}/background_survey",
			    delta_setting: false,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]
			expect(retval).to eq(true)
			survey = Survey.where("id" => @survey.id).first
			expect(survey.delta).to eq(false)
		end

		describe "with reward_scheme not exist" do


			it "the /quillme_promote of survey should return REWARD_SCHEME_NOT_EXIST" do
				put "/admin/surveys/#{@survey.id}/quillme_promote",
				    quillme_promote_setting: true,
			    	auth_key: @auth_key
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end

			it "the /email_promote of survey should return REWARD_SCHEME_NOT_EXIST" do
				put "/admin/surveys/#{@survey.id}/email_promote", 
			    	auth_key: @auth_key
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end

			it "the /sms_promote of survey should return REWARD_SCHEME_NOT_EXIST" do
				put "/admin/surveys/#{@survey.id}/sms_promote", 
			    	auth_key: @auth_key
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end

			it "the /broswer_extension_promote of survey should return REWARD_SCHEME_NOT_EXIST" do
				put "/admin/surveys/#{@survey.id}/broswer_extension_promote", 
			    	auth_key: @auth_key
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end

			it "the /weibo_promote of survey should return all promote value" do
				put "/admin/surveys/#{@survey.id}/weibo_promote", 
			    	auth_key: @auth_key
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end
		end

		describe "with reward_scheme exist" do
			before(:each) do
				@reward_scheme = FactoryGirl.create(:reward_scheme)
			end

			it "submit /quillme_promote of survey should return true" do
				put "/admin/surveys/#{@survey.id}/quillme_promote",
				    quillme_promote_setting: true,
				    reward_scheme_id: @reward_scheme.id,
			    	auth_key: @auth_key
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.where("id" => @survey.id).first
				expect(survey.quillme_promote).to eq(true)
			end

			it "submit /email_promote of survey should return true" do
				email_promote = @survey.email_promote
				email_promote['promotable'] = true
				email_promote['email_amount'] = 5000
				email_promote['promote_to_undefined_sample'] = false
				put "/admin/surveys/#{@survey.id}/email_promote",
				    JSON.dump(
				    email_promote_setting: email_promote,
				    reward_scheme_id: @reward_scheme.id.to_s,
			    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.where("id" => @survey.id).first
				expect(email_promote).to eq(survey.email_promote)
			end

			it "submit /sms_promote of survey should return true" do
				sms_promote = @survey.sms_promote
				sms_promote['promotable'] = true
				sms_promote['sms_amount'] = 5000
				sms_promote['promote_to_undefined_sample'] = false
				put "/admin/surveys/#{@survey.id}/sms_promote",
				    JSON.dump(
				    sms_promote_setting: sms_promote,
				    reward_scheme_id: @reward_scheme.id.to_s,
			    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"				    
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.where("id" => @survey.id).first
				expect(sms_promote).to eq(survey.sms_promote)
			end

			it "submit /broswer_extension_promote of survey should return true" do
				broswer_extension_promote = @survey.broswer_extension_promote
				broswer_extension_promote['promotable'] = true
				broswer_extension_promote['login_sample_promote_only'] = true
				broswer_extension_promote['filter'] = 
				[ [{"key_word" => ["hello"], "url" => "sina"}],
				[{"key_word" => ["bye"], "url" => "qq"}] ]
				put "/admin/surveys/#{@survey.id}/broswer_extension_promote", 
				    JSON.dump(
				    broswer_extension_promote_setting: broswer_extension_promote,
				    reward_scheme_id: @reward_scheme.id.to_s,
			    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.where("id" => @survey.id).first
				expect(broswer_extension_promote).to eq(survey.broswer_extension_promote)
			end

			it "submit /weibo_promote of survey should return true" do
				weibo_promote = @survey.weibo_promote
				weibo_promote['text'] = "welcome to our website"
				weibo_promote['image'] = "https://secure.gravatar.com/avatar/1d41b66ab243250e4268869049dfffc4?s=140&d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png"
				weibo_promote['vidio'] = "http://youku.com"
				weibo_promote['audio'] = "http://mp3.baidu.com"
				put "/admin/surveys/#{@survey.id}/weibo_promote",
				    JSON.dump(
				    weibo_promote_setting: weibo_promote,
				    reward_scheme_id: @reward_scheme.id.to_s,
			    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.where("id" => @survey.id).first
				expect(weibo_promote).to eq(survey.weibo_promote)
			end
		end

		after(:each) do
			clear(:Survey)
			clear(:RewardScheme)
			clear(:Prize)
		end
	end

	describe "verify respone message correct" do
		before(:all) do
			@surveys = FactoryGirl.create_list(:survey, 20)
			@creator1 = FactoryGirl.create(:survey_creator)
			@creator2 = FactoryGirl.create(:survey_creator)
			@surveys[0..9].each { |s| @creator1.surveys << s}
			@surveys[10..19].each { |s| @creator2.surveys << s}
		end

        ### status filter test
		it "the /index select by status 1 should find 6 results" do
			get "/admin/surveys",
			    status: 1,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(7)
		end

		it "the /index select by status 4 should find 6 results" do
			get "/admin/surveys",
			    status: 4,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(6)
		end

		it "the /index select by status 6 should find 10 results" do
			get "/admin/surveys",
			    status: 6,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(10)
		end

		it "the /index select by status 6 with per_page 15 should find 13 results" do
			get "/admin/surveys",
			    status: 6,
			    page: 1,
			    per_page: 15,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(13)
		end

		it "the /index select by status 7 with per_page 18 should find 18 results" do
			get "/admin/surveys",
			    status: 7,
			    page: 1,
			    per_page: 18,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(18)
		end

		## title filter test
		it "the /index select by title title3 should find 6 results" do
			get "/admin/surveys",
			    title: "title3",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(7)
		end

		it "the /index select by title 38 should find 1 results" do
			get "/admin/surveys",
			    title: "38",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(1)
		end

		it "the /index select by title 3news should find 2 results" do
			get "/admin/surveys",
			    title: "3news",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(2)
		end

		## email filter test

		it "the /index select by user_email of creator1 should find 10 results" do
			get "/admin/surveys",
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(10)
		end

		it "the /index select by user_email unknown should find 0 results" do
			get "/admin/surveys",
			    email: "unknown@text.com",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(0)
		end

		## mobile filter test

		it "the /index select by user_mobile of creator1 should find 10 results" do
			get "/admin/surveys",
			    mobile: @creator1.mobile,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(10)
		end

		it "the /index select by user_mobile unknown should find 0 results" do
			get "/admin/surveys",
			    mobile: "18354586800",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(0)
		end

		## complex filter test
		it "the /index select by status|title should find 3 results" do
			get "/admin/surveys",
			    status: 1,
			    title: "title3",
			    mobile: "",
			    email: "",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(3)
		end

		it "the /index select by status|mobile should find 4 results" do
			get "/admin/surveys",
			    status: 1,
			    title: "",
			    mobile: @creator1.mobile,
			    email: "",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(4)
		end

		it "the /index select by status|email should find 4 results" do
			get "/admin/surveys",
			    status: 1,
			    title: "",
			    mobile: "",
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(4)
		end

		it "the /index select by title|email should find 7 results" do
			get "/admin/surveys",
			    status: "",
			    title: "title3",
			    mobile: @creator1.mobile,
			    email: "",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(7)
		end

		it "the /index select by title|email should find 7 results" do
			get "/admin/surveys",
			    status: "",
			    title: "title3",
			    mobile: "",
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(7)
		end

		it "the /index select by mobile|email should find 0 results" do
			get "/admin/surveys",
			    status: "",
			    title: "",
			    mobile: @creator2.mobile,
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(0)
		end

		it "the /index select by status|mobile|email should find 4 results" do
			get "/admin/surveys",
			    status: 1,
			    title: "",
			    mobile: @creator1.mobile,
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(4)
		end

		it "the /index select by title|mobile|email should find 7 results" do
			get "/admin/surveys",
			    status: "",
			    title: "title3",
			    mobile: @creator1.mobile,
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(7)
		end

		it "the /index select by status|title|mobile|email should find 4 results" do
			get "/admin/surveys",
			    status: 6,
			    title: "title3",
			    mobile: @creator1.mobile,
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(4)
		end


		after(:all) do
			clear(:Survey)
		end
	end

end
