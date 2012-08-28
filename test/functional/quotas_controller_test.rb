require 'test_helper'

class QuotasControllerTest < ActionController::TestCase
	test "should add quota rule" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)


		quota_rule = {}
		quota_rule["amount"] = 100
		quota_rule["conditions"] = []
		quota_rule["conditions"] << {"condition_type" => 3, "name" => "channel", "value" => "1"}
		quota_rule["conditions"] << {"condition_type" => 4, "name" => "ip", "value" => "166.111.*.*"}

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :quota_rule => quota_rule
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		quota_rule["amount"] = 0
		post :create, :format => :json, :survey_id => survey_id, :quota_rule => quota_rule
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_QUOTA_RULE_AMOUNT.to_s, result["value"]["error_code"]
		quota_rule["amount"] = 100
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		quota_rule["conditions"][0]["condition_type"] = -1
		post :create, :format => :json, :survey_id => survey_id, :quota_rule => quota_rule
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE.to_s, result["value"]["error_code"]
		quota_rule["conditions"][0]["condition_type"] = 3
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :quota_rule => quota_rule
		result = JSON.parse(@response.body)
		quota = result["value"]
		assert_equal 1, quota["rules"].length
		assert_equal 100, quota["rules"][0]["amount"]
		assert_equal 2, quota["rules"][0]["conditions"].length
		assert_equal 3, quota["rules"][0]["conditions"][0]["condition_type"]
		assert_equal "166.111.*.*", quota["rules"][0]["conditions"][1]["value"]
		get :show, :format => :json, :survey_id => survey_id, :id => 0
		result = JSON.parse(@response.body)
		quota_rule = result["value"]
		assert_equal 100, quota_rule["amount"]
		assert_equal 2, quota_rule["conditions"].length
		assert_equal 3, quota_rule["conditions"][0]["condition_type"]
		assert_equal "166.111.*.*", quota_rule["conditions"][1]["value"]
		sign_out

	end

	test "should update quota rule" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)

		quota_rule = {}
		quota_rule["amount"] = 100
		quota_rule["conditions"] = []
		quota_rule["conditions"] << {"condition_type" => 3, "name" => "channel", "value" => "1"}
		quota_rule["conditions"] << {"condition_type" => 4, "name" => "ip", "value" => "166.111.*.*"}

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :quota_rule => quota_rule
		sign_out


		quota_rule["amount"] = 1000
		quota_rule["conditions"].delete_at(1)


		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 1, :quota_rule => quota_rule
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUOTA_RULE_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		quota_rule["amount"] = 0
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :quota_rule => quota_rule
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_QUOTA_RULE_AMOUNT.to_s, result["value"]["error_code"]
		quota_rule["amount"] = 1000
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		quota_rule["conditions"][0]["condition_type"] = -1
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :quota_rule => quota_rule
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE.to_s, result["value"]["error_code"]
		quota_rule["conditions"][0]["condition_type"] = 3
		sign_out


		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :quota_rule => quota_rule
		result = JSON.parse(@response.body)
		quota = result["value"]
		assert_equal 1, quota["rules"].length
		assert_equal 1000, quota["rules"][0]["amount"]
		assert_equal 1, quota["rules"][0]["conditions"].length
		assert_equal 3, quota["rules"][0]["conditions"][0]["condition_type"]
		get :show, :format => :json, :survey_id => survey_id, :id => 0
		result = JSON.parse(@response.body)
		quota_rule = result["value"]
		assert_equal 1000, quota_rule["amount"]
		assert_equal 1, quota_rule["conditions"].length
		assert_equal 3, quota_rule["conditions"][0]["condition_type"]
		sign_out
	end

	test "should delete quota rule" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)

		quota_rule = {}
		quota_rule["amount"] = 100
		quota_rule["conditions"] = []
		quota_rule["conditions"] << {"condition_type" => 3, "name" => "channel", "value" => "1"}
		quota_rule["conditions"] << {"condition_type" => 4, "name" => "ip", "value" => "166.111.*.*"}

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :quota_rule => quota_rule
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 1
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::QUOTA_RULE_NOT_EXIST.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 0
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		get :index, :format => :json, :survey_id => survey_id
		result = JSON.parse(@response.body)
		quota = result["value"]
		assert_equal 0, quota["rules"].length
		sign_out
	end

	test "should set exclusive for quota" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :set_exclusive, :format => :json, :survey_id => survey_id, :is_exclusive => false
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :get_exclusive, :format => :json, :survey_id => survey_id
		result = JSON.parse(@response.body)
		assert_equal false, result["value"]
		sign_out
	end

end
