require 'test_helper'

class FiltersControllerTest < ActionController::TestCase
	test "should add filter" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)


		filter = {}
		filter["name"] = "filter1"
		filter["conditions"] = []
		filter["conditions"] << {"condition_type" => 3, "name" => "channel", "value" => "1"}
		filter["conditions"] << {"condition_type" => 4, "name" => "ip", "value" => "166.111.*.*"}

		auth_key = sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :filter => filter, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		filter["conditions"][0]["condition_type"] = -1
		post :create, :format => :json, :survey_id => survey_id, :filter => filter, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_FILTER_CONDITION_TYPE.to_s, result["value"]["error_code"]
		filter["conditions"][0]["condition_type"] = 3
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :filter => filter, :auth_key => auth_key
		result = JSON.parse(@response.body)
		filters = result["value"]
		assert_equal 1, filters.length
		assert_equal "filter1", filters[0]["name"]
		assert_equal 2, filters[0]["conditions"].length
		assert_equal 3, filters[0]["conditions"][0]["condition_type"]
		assert_equal "166.111.*.*", filters[0]["conditions"][1]["value"]
		get :show, :format => :json, :survey_id => survey_id, :id => 0, :auth_key => auth_key
		result = JSON.parse(@response.body)
		filter = result["value"]
		assert_equal "filter1", filter["name"]
		assert_equal 2, filter["conditions"].length
		assert_equal 3, filter["conditions"][0]["condition_type"]
		assert_equal "166.111.*.*", filter["conditions"][1]["value"]
		sign_out(auth_key)

	end

	test "should update filter" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)

		filter = {}
		filter["name"] = "filter1"
		filter["conditions"] = []
		filter["conditions"] << {"condition_type" => 3, "name" => "channel", "value" => "1"}
		filter["conditions"] << {"condition_type" => 4, "name" => "ip", "value" => "166.111.*.*"}

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :filter => filter, :auth_key => auth_key
		sign_out(auth_key)


		filter["name"] = "new filter name"
		filter["conditions"].delete_at(1)


		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 1, :filter => filter, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::FILTER_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		filter["conditions"][0]["condition_type"] = -1
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :filter => filter, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_FILTER_CONDITION_TYPE.to_s, result["value"]["error_code"]
		filter["conditions"][0]["condition_type"] = 3
		sign_out(auth_key)


		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :filter => filter, :auth_key => auth_key
		result = JSON.parse(@response.body)
		filters = result["value"]
		assert_equal 1, filters.length
		assert_equal "new filter name", filters[0]["name"]
		assert_equal 1, filters[0]["conditions"].length
		assert_equal 3, filters[0]["conditions"][0]["condition_type"]
		get :show, :format => :json, :survey_id => survey_id, :id => 0, :auth_key => auth_key
		result = JSON.parse(@response.body)
		filter = result["value"]
		assert_equal "new filter name", filter["name"]
		assert_equal 1, filter["conditions"].length
		assert_equal 3, filter["conditions"][0]["condition_type"]
		sign_out(auth_key)
	end

	test "should delete filter" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)

		filter = {}
		filter["name"] = "filter1"
		filter["conditions"] = []
		filter["conditions"] << {"condition_type" => 3, "name" => "channel", "value" => "1"}
		filter["conditions"] << {"condition_type" => 4, "name" => "ip", "value" => "166.111.*.*"}

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :filter => filter, :auth_key => auth_key
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 1, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::FILTER_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 0, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :index, :format => :json, :survey_id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		filters = result["value"]
		assert_equal 0, filters.length
		sign_out(auth_key)
	end
end
