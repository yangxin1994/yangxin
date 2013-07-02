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

		it "the /allocate_answer_auditors should return SURVEY_NOT_EXIST" do
			put "/admin/surveys/1/allocate_answer_auditors",
			  answer_auditor_ids: [],
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
			expect(retval["user"]["id"]).to eq(@survey.user._id.to_s)
			expect(retval["user"]["email"]).to eq(@survey.user.email)
			expect(retval["user"]["mobile"]).to eq(@survey.user.mobile)
			expect(retval["survey"]["id"]).to eq(@survey._id.to_s)
		end

		it "the /promote of surveys should return true" do
			promote = {}
			promote["quillme_promotable"] = @survey.quillme_promotable
			promote['quillme_promote_info'] = @survey.quillme_promote_info
			promote["email_promotable"] = @survey.email_promotable
			promote['email_promote_info'] = @survey.email_promote_info
			promote["sms_promotable"] = @survey.sms_promotable
			promote['sms_promote_info'] = @survey.sms_promote_info
			promote["broswer_extension_promotable"] = @survey.broswer_extension_promotable
			promote['broswer_extension_promote_info'] = @survey.broswer_extension_promote_info
			promote["weibo_promotable"] = @survey.weibo_promotable
			promote['weibo_promote_info'] = @survey.weibo_promote_info
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

		it "the /allocate_answer_auditors should return true" do
			answer_auditor = FactoryGirl.create(:answer_auditor)
			expect(User.find_by_id(answer_auditor.id.to_s).answer_auditor_allocated_surveys.length).to eq(0)
			put "/admin/surveys/#{@survey.id}/allocate_answer_auditors",
			  answer_auditor_ids: [answer_auditor.id.to_s],
			  allocate: true,
			  auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]
			expect(retval).to eq(true)
			expect(User.find_by_id(answer_auditor.id.to_s).answer_auditor_allocated_surveys.length).to eq(1)
		end

		it "the /allocate_answer_auditors should return true" do
			answer_auditor = FactoryGirl.create(:answer_auditor)
			answer_auditor.answer_auditor_allocated_surveys << @survey
			expect(User.find_by_id(answer_auditor.id.to_s).answer_auditor_allocated_surveys.length).to eq(1)
			put "/admin/surveys/#{@survey.id}/allocate_answer_auditors",
			  answer_auditor_ids: [answer_auditor.id.to_s],
			  allocate: false,
			  auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]
			expect(retval).to eq(true)
			expect(User.find_by_id(answer_auditor.id.to_s).answer_auditor_allocated_surveys.length).to eq(0)
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
				email_promote_setting = {}
				email_promote_setting["email_amount"] = 5000
				email_promote_setting["promote_to_undefined_sample"] = true
				email_promote_setting["reward_scheme_id"] = ""
				put "/admin/surveys/#{@survey.id}/email_promote", 
				    JSON.dump(
				    	promotable: true,
				    	email_promote_setting: email_promote_setting,
				    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end

			it "the /sms_promote of survey should return REWARD_SCHEME_NOT_EXIST" do
				sms_promote_setting = {}
				sms_promote_setting["sms_amount"] = 5000
				sms_promote_setting["promote_to_undefined_sample"] = true
				sms_promote_setting["reward_scheme_id"] = ""
				put "/admin/surveys/#{@survey.id}/sms_promote", 
			    	JSON.dump(
				    	promotable: true,
				    	sms_promote_setting: sms_promote_setting,
				    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end

			it "the /broswer_extension_promote of survey should return REWARD_SCHEME_NOT_EXIST" do
				broswer_extension_promote_setting = {}
				broswer_extension_promote_setting["reward_scheme_id"] = ""
				put "/admin/surveys/#{@survey.id}/broswer_extension_promote", 
			    	JSON.dump(
				    	promotable: true,
				    	broswer_extension_promote_setting: broswer_extension_promote_setting,
				    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end

			it "the /weibo_promote of survey should return all promote value" do
				weibo_promote_setting = {}
				weibo_promote_setting["reward_scheme_id"] = ""
				put "/admin/surveys/#{@survey.id}/weibo_promote", 
			    	JSON.dump(
				    	promotable: true,
				    	weibo_promote_setting: weibo_promote_setting,
				    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]["error_code"]
				expect(retval).to eq(ErrorEnum::REWARD_SCHEME_NOT_EXIST)
			end
		end

		describe "with reward_scheme exist" do
			before(:each) do
				@rs = FactoryGirl.create(:reward_scheme)
			end

			it "submit /quillme_promote of survey should return true" do
				put "/admin/surveys/#{@survey.id}/quillme_promote",
				    JSON.dump(
				    	promotable: true,
				    	quillme_promote_setting: {"reward_scheme_id" => @rs.id.to_s},
				    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.find_by_id(@survey.id)
				expect(survey.quillme_promotable).to eq(true)
			end

			it "submit /email_promote of survey should return true" do
				email_promote = {}
				email_promote['email_amount'] = 5000
				email_promote['promote_to_undefined_sample'] = true
				email_promote["reward_scheme_id"] = @rs.id.to_s
				put "/admin/surveys/#{@survey.id}/email_promote",
				    JSON.dump(
				    	email_promotable: true,
				    	email_promote_setting: email_promote,
				    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.find_by_id(@survey.id)
				email_promote["promote_email_count"] = 0
				expect(email_promote).to eq(survey.email_promote_info)
			end

			it "submit /sms_promote of survey should return true" do
				sms_promote = {}
				sms_promote['sms_amount'] = 5000
				sms_promote['promote_to_undefined_sample'] = false
				sms_promote["reward_scheme_id"] = @rs.id.to_s
				put "/admin/surveys/#{@survey.id}/sms_promote",
				    JSON.dump(
				    	sms_promotable: true,
				    	sms_promote_setting: sms_promote,
    			    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"				    
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.find_by_id(@survey.id)
				sms_promote["promote_sms_count"] = 0
				expect(sms_promote).to eq(survey.sms_promote_info)
			end

			it "submit /broswer_extension_promote of survey should return true" do
				broswer_extension_promote = {}
				broswer_extension_promote['login_sample_promote_only'] = true
				broswer_extension_promote['filter'] = 
				[ [{"key_word" => ["hello"], "url" => "sina"}],
				[{"key_word" => ["bye"], "url" => "qq"}] ]
				broswer_extension_promote["reward_scheme_id"] = @rs.id.to_s
				put "/admin/surveys/#{@survey.id}/broswer_extension_promote", 
				    JSON.dump(
				    	broswer_extension_promotable: true,
				    	broswer_extension_promote_setting: broswer_extension_promote,
				    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.find_by_id(@survey.id)
				expect(broswer_extension_promote).to eq(survey.broswer_extension_promote_info)
			end

			it "submit /weibo_promote of survey should return true" do
				weibo_promote = {}
				weibo_promote['text'] = "welcome to our website"
				weibo_promote['image'] = "https://secure.gravatar.com/avatar/1d41b66ab243250e4268869049dfffc4?s=140&d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png"
				weibo_promote['vidio'] = "http://youku.com"
				weibo_promote['audio'] = "http://mp3.baidu.com"
				weibo_promote["reward_scheme_id"] = @rs.id.to_s
				put "/admin/surveys/#{@survey.id}/weibo_promote",
				    JSON.dump(
				    	weibo_promotable: true,
				    	weibo_promote_setting: weibo_promote,
    			    	auth_key: @auth_key),
			    	"CONTENT_TYPE" => "application/json"
				response.status.should be(200)
				retval = JSON.parse(response.body)["value"]
				expect(retval).to eq(true)
				survey = Survey.find_by_id(@survey.id)
				expect(weibo_promote).to eq(survey.weibo_promote_info)
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
			@results = []
			@surveys.each {|s| @results << [s.status, s.title, s.user.email, s.user.mobile] }
		end

        ### status filter test
		it "the /index select by status 1 should find 6|7 results" do
			get "/admin/surveys",
			    status: 1,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[0] == 1 }
			expect(retval.length).to eq(count)
		end

		it "the /index select by status 4 should find 6|7 results" do
			get "/admin/surveys",
			    status: 4,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[0] == 4 }
			expect(retval.length).to eq(count)
		end

		it "the /index select by status 6 should find 10 results" do
			get "/admin/surveys",
			    status: 6,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(10)
		end

		it "the /index select by status 6 with per_page 15 should find 13|14 results" do
			get "/admin/surveys",
			    status: 6,
			    page: 1,
			    per_page: 15,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[0] != 1 }
			expect(retval.length).to eq(count)
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
		it "the /index select by title should find 7 results" do
			title = @results[0][1][0..5]
			get "/admin/surveys",
			    title: title,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[1].include?(title) }
			expect(retval.length).to eq(count)
		end

		it "the /index select by only title should find 1 results" do
			title = @results[0][1][5..6]
			get "/admin/surveys",
			    title: title,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			expect(retval.length).to eq(1)
		end

		it "the /index select by title 3news should find 2 results" do
			title = @results[-1][1][6..-1]
			get "/admin/surveys",
			    title: title,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[1].include?(title) }
			expect(retval.length).to eq(count)
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
			title = @results[0][1][0..5]
			get "/admin/surveys",
			    status: 1,
			    title: title,
			    mobile: "",
			    email: "",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[1].include?(title) and s[0] == 1}
			expect(retval.length).to eq(count)
		end

		it "the /index select by status|mobile should find right results" do
			get "/admin/surveys",
			    status: 1,
			    title: "",
			    mobile: @creator1.mobile,
			    email: "",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[3] == @creator1.mobile and s[0] == 1}
			expect(retval.length).to eq(count)
		end

		it "the /index select by status|email should find right results" do
			get "/admin/surveys",
			    status: 1,
			    title: "",
			    mobile: "",
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[2] == @creator1.email and s[0] == 1}
			expect(retval.length).to eq(count)
		end

		it "the /index select by title|email should find right results" do
			title = @results[0][1][0..5]
			get "/admin/surveys",
			    status: "",
			    title: title,
			    mobile: @creator1.mobile,
			    email: "",
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[1].include?(title) and s[3] == @creator1.mobile}
			expect(retval.length).to eq(count)
		end

		it "the /index select by title|email should find right results" do
			title = @results[0][1][0..5]
			get "/admin/surveys",
			    status: "",
			    title: title,
			    mobile: "",
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[1].include?(title) and s[2] == @creator1.email}
			expect(retval.length).to eq(count)
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

		it "the /index select by status|mobile|email should find right results" do
			get "/admin/surveys",
			    status: 1,
			    title: "",
			    mobile: @creator1.mobile,
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[0] == 1 and s[2] == @creator1.email and s[3] == @creator1.mobile}
			expect(retval.length).to eq(count)
		end

		it "the /index select by title|mobile|email should find right results" do
			title = @results[0][1][0..5]
			get "/admin/surveys",
			    status: "",
			    title: title,
			    mobile: @creator1.mobile,
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[1].include?(title) and s[2] == @creator1.email and s[3] == @creator1.mobile}
			expect(retval.length).to eq(count)
		end

		it "the /index select by status|title|mobile|email should find right results" do
			title = @results[0][1][0..5]
			get "/admin/surveys",
			    status: 6,
			    title: title,
			    mobile: @creator1.mobile,
			    email: @creator1.email,
		    	auth_key: @auth_key
			response.status.should be(200)
			retval = JSON.parse(response.body)["value"]["data"]
			count = 0
			@results.each { |s| count += 1 if s[1].include?(title) and s[2] == @creator1.email and s[3] == @creator1.mobile and s[0] != 1}
			expect(retval.length).to eq(count)
		end


		after(:all) do
			clear(:Survey)
		end
	end

end
