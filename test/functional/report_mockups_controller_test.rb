require 'test_helper'

class ReportMockupsControllerTest < ActionController::TestCase
	test "should create report mockup" do
		clear(User, Survey, ReportMockup)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)	

		questions = pages.flatten

		report_mockup = {}
		report_mockup["title"] = "title of the report"
		report_mockup["subtitle"] = "subtitle of the report"
		report_mockup["header"] = "header of the report"
		report_mockup["footer"] = "footer of the report"
		report_mockup["author"] = "author of the report"
		report_mockup["chart_style"] = {"single_style" => 0, "cross_style" => -1}
		report_mockup["components"] = []
		report_mockup["components"] << {"component_type" => 0, "value" => {"id" => questions[0], "format" => []}}
		report_mockup["components"] << {"component_type" => 1, "value" => {"id" => questions[0], "target" => {"id" => questions[1], "format" => []} } }

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		report_mockup["chart_style"]["single_style"] = -2
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_REPORT_MOCKUP_CHART_STYLE.to_s, result["value"]["error_code"]
		report_mockup["chart_style"]["single_style"] = 0
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		report_mockup["components"][0]["component_type"] = -1
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_REPORT_MOCKUP_COMPONENT_TYPE.to_s, result["value"]["error_code"]
		report_mockup["components"][0]["component_type"] = 0
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		report_mockup["components"][0]["value"]["id"] = "wrong question id"
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, result["value"]["error_code"]
		report_mockup["components"][0]["value"]["id"] = questions[0]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		report_mockup = result["value"]
		assert_equal survey_id, report_mockup["survey_id"]
		assert_equal "title of the report", report_mockup["title"]
		assert_equal "subtitle of the report", report_mockup["subtitle"]
		assert_equal "header of the report", report_mockup["header"]
		assert_equal "footer of the report", report_mockup["footer"]
		assert_equal "author of the report", report_mockup["author"]
		assert_equal 0, report_mockup["chart_style"]["single_style"]
		assert_equal -1, report_mockup["chart_style"]["cross_style"]
		assert_equal 2, report_mockup["components"].length
		assert_equal 0, report_mockup["components"][0]["component_type"]
		assert_equal questions[0], report_mockup["components"][0]["value"]["id"]
		assert_equal 1, report_mockup["components"][1]["component_type"]
		assert_equal questions[0], report_mockup["components"][1]["value"]["id"]
		assert_equal questions[1], report_mockup["components"][1]["value"]["target"]["id"]
		get :show, :format => :json, :survey_id => survey_id, :id => report_mockup["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		report_mockup = result["value"]
		assert_equal survey_id, report_mockup["survey_id"]
		assert_equal "title of the report", report_mockup["title"]
		assert_equal "subtitle of the report", report_mockup["subtitle"]
		assert_equal "header of the report", report_mockup["header"]
		assert_equal "footer of the report", report_mockup["footer"]
		assert_equal "author of the report", report_mockup["author"]
		assert_equal 0, report_mockup["chart_style"]["single_style"]
		assert_equal -1, report_mockup["chart_style"]["cross_style"]
		assert_equal 2, report_mockup["components"].length
		assert_equal 0, report_mockup["components"][0]["component_type"]
		assert_equal questions[0], report_mockup["components"][0]["value"]["id"]
		assert_equal 1, report_mockup["components"][1]["component_type"]
		assert_equal questions[0], report_mockup["components"][1]["value"]["id"]
		assert_equal questions[1], report_mockup["components"][1]["value"]["target"]["id"]
		sign_out(auth_key)
	end

	test "should update report mockup" do
		clear(User, Survey, ReportMockup)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)	

		questions = pages.flatten

		report_mockup = {}
		report_mockup["title"] = "title of the report"
		report_mockup["subtitle"] = "subtitle of the report"
		report_mockup["header"] = "header of the report"
		report_mockup["footer"] = "footer of the report"
		report_mockup["author"] = "author of the report"
		report_mockup["chart_style"] = {"single_style" => 0, "cross_style" => -1}
		report_mockup["components"] = []
		report_mockup["components"] << {"component_type" => 0, "value" => {"id" => questions[0], "format" => []}}
		report_mockup["components"] << {"component_type" => 1, "value" => {"id" => questions[0], "target" => {"id" => questions[1], "format" => []} } }

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		report_mockup = result["value"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		report_mockup["chart_style"]["single_style"] = -2
		put :update, :format => :json, :survey_id => survey_id, :id => report_mockup["_id"], :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_REPORT_MOCKUP_CHART_STYLE.to_s, result["value"]["error_code"]
		report_mockup["chart_style"]["single_style"] = 0
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		report_mockup["components"][0]["component_type"] = -1
		put :update, :format => :json, :survey_id => survey_id, :id => report_mockup["_id"], :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_REPORT_MOCKUP_COMPONENT_TYPE.to_s, result["value"]["error_code"]
		report_mockup["components"][0]["component_type"] = 0
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		report_mockup["components"] << {"component_type" => 1, "value" => {"id" => questions[3], "target" => {"id" => questions[1]} }}
		put :update, :format => :json, :survey_id => survey_id, :id => report_mockup["_id"], :report_mockup => report_mockup, :auth_key => auth_key
		result = JSON.parse(@response.body)
		report_mockup = result["value"]
		assert_equal 3, report_mockup["components"].length
		assert_equal 1, report_mockup["components"][2]["component_type"]
		assert_equal questions[3], report_mockup["components"][2]["value"]["id"]
		assert_equal questions[1], report_mockup["components"][2]["value"]["target"]["id"]
		get :show, :format => :json, :survey_id => survey_id, :id => report_mockup["_id"], :auth_key => auth_key
		result = JSON.parse(@response.body)
		report_mockup = result["value"]
		assert_equal 3, report_mockup["components"].length
		assert_equal 1, report_mockup["components"][2]["component_type"]
		assert_equal questions[3], report_mockup["components"][2]["value"]["id"]
		assert_equal questions[1], report_mockup["components"][2]["value"]["target"]["id"]
		sign_out(auth_key)
	end

	test "should list report mockup" do
		clear(User, Survey, ReportMockup)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)	

		questions = pages.flatten

		report_mockup = {}
		report_mockup["title"] = "title of the report"
		report_mockup["subtitle"] = "subtitle of the report"
		report_mockup["header"] = "header of the report"
		report_mockup["footer"] = "footer of the report"
		report_mockup["author"] = "author of the report"
		report_mockup["chart_style"] = {"single_style" => 0, "cross_style" => -1}
		report_mockup["components"] = []
		report_mockup["components"] << {"component_type" => 0, "value" => {"id" => questions[0], "format" => []}}
		report_mockup["components"] << {"component_type" => 1, "value" => {"id" => questions[0], "target" => {"id" => questions[1], "format" => []} } }

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		sign_out(auth_key)

		report_mockup["title"] = "second report"
		report_mockup["chart_style"] = {"single_style" => 4, "cross_style" => 3}
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		sign_out(auth_key)

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :index, :format => :json, :survey_id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::SURVEY_NOT_EXIST, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :survey_id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal 2, result["value"].length
		assert_equal "title of the report", result["value"][0]["title"]
		assert_equal 0, result["value"][0]["chart_style"]["single_style"]
		assert_equal -1, result["value"][0]["chart_style"]["cross_style"]
		assert_equal "second report", result["value"][1]["title"]
		assert_equal 4, result["value"][1]["chart_style"]["single_style"]
		assert_equal 3, result["value"][1]["chart_style"]["cross_style"]
		sign_out(auth_key)
	end

	test "should delete report mockup" do
		clear(User, Survey, ReportMockup)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)	

		questions = pages.flatten

		report_mockup = {}
		report_mockup["title"] = "title of the report"
		report_mockup["subtitle"] = "subtitle of the report"
		report_mockup["header"] = "header of the report"
		report_mockup["footer"] = "footer of the report"
		report_mockup["author"] = "author of the report"
		report_mockup["chart_style"] = {"single_style" => 0, "cross_style" => -1}
		report_mockup["components"] = []
		report_mockup["components"] << {"component_type" => 0, "value" => {"id" => questions[0], "format" => []}}
		report_mockup["components"] << {"component_type" => 1, "value" => {"id" => questions[0], "target" => {"id" => questions[1], "format" => []} } }

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		report_mockup_id_1 = JSON.parse(@response.body)["value"]["_id"]
		sign_out(auth_key)

		report_mockup["title"] = "second report"
		report_mockup["chart_style"] = {"single_style" => 4, "cross_style" => 3}
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :report_mockup => report_mockup, :auth_key => auth_key
		report_mockup_id_2 = JSON.parse(@response.body)["value"]["_id"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => report_mockup_id_1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert result["success"]
		assert result["value"]
		get :index, :format => :json, :survey_id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal 1, result["value"].length
		assert_equal "second report", result["value"][0]["title"]
		assert_equal 4, result["value"][0]["chart_style"]["single_style"]
		assert_equal 3, result["value"][0]["chart_style"]["cross_style"]
		sign_out(auth_key)
	end
end
