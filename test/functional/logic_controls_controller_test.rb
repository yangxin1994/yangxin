require 'test_helper'

class LogicControlsControllerTest < ActionController::TestCase
	test "should add logic control rule" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)
		insert_page(jesse.email, jesse.password, survey_id, -1, "first page")

		q1_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)
		q2_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)
		q3_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)

		question_1 = show_question(jesse.email, jesse.password, survey_id, q1_id)

		logic_control_rule = {}
		logic_control_rule["rule_type"] = 0
		logic_control_rule["conditions"] = []
		logic_control_rule["conditions"] << {"question_id" => q1_id, "result" => [question_1["issue"]["choices"][0]["input_id"]], "fuzzy" => true}
		logic_control_rule["result"] = nil

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		logic_control_rule["rule_type"] = -1
		post :create, :format => :json, :survey_id => survey_id, :logic_control_rule => logic_control_rule
		assert_equal ErrorEnum::WRONG_LOGIC_CONTROL_TYPE.to_s, @response.body
		logic_control_rule["rule_type"] = 0
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :logic_control_rule => logic_control_rule
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :logic_control_rule => logic_control_rule
		logic_control = JSON.parse(@response.body)
		assert_equal 1, logic_control.length
		assert_equal 0, logic_control[0]["rule_type"]
		assert_equal 1, logic_control[0]["conditions"].length
		assert_equal q1_id, logic_control[0]["conditions"][0]["question_id"]
		get :show, :format => :json, :survey_id => survey_id, :id => 0
		logic_control_rule = JSON.parse(@response.body)
		assert_equal 0, logic_control_rule["rule_type"]
		assert_equal 1, logic_control_rule["conditions"].length
		assert_equal q1_id, logic_control_rule["conditions"][0]["question_id"]
		sign_out

	end

	test "should update logic control rule" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)
		insert_page(jesse.email, jesse.password, survey_id, -1, "first page")

		q1_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)
		q2_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)
		q3_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)

		question_1 = show_question(jesse.email, jesse.password, survey_id, q1_id)

		logic_control_rule = {}
		logic_control_rule["rule_type"] = 0
		logic_control_rule["conditions"] = []
		logic_control_rule["conditions"] << {"question_id" => q1_id, "result" => [question_1["issue"]["choices"][0]["input_id"]], "fuzzy" => true}
		logic_control_rule["result"] = nil

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :logic_control_rule => logic_control_rule
		sign_out

		logic_control_rule["conditions"][0]["fuzzy"] = false


		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		logic_control_rule["rule_type"] = -1
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :logic_control_rule => logic_control_rule
		assert_equal ErrorEnum::WRONG_LOGIC_CONTROL_TYPE.to_s, @response.body
		logic_control_rule["rule_type"] = 0
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 1, :logic_control_rule => logic_control_rule
		assert_equal ErrorEnum::LOGIC_CONTROL_RULE_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :logic_control_rule => logic_control_rule
		logic_control = JSON.parse(@response.body)
		assert_equal false, logic_control[0]["conditions"][0]["fuzzy"]
		get :show, :format => :json, :survey_id => survey_id, :id => 0
		logic_control_rule = JSON.parse(@response.body)
		assert_equal false, logic_control_rule["conditions"][0]["fuzzy"]
		sign_out
	end

	test "should delete logic control rule" do
		clear(User, Survey)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_closed_survey(jesse)
		insert_page(jesse.email, jesse.password, survey_id, -1, "first page")

		q1_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)
		q2_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)
		q3_id = create_choice_question_with_choices(jesse.email, jesse.password, survey_id, 0, -1, 0)

		question_1 = show_question(jesse.email, jesse.password, survey_id, q1_id)

		logic_control_rule = {}
		logic_control_rule["rule_type"] = 0
		logic_control_rule["conditions"] = []
		logic_control_rule["conditions"] << {"question_id" => q1_id, "result" => [question_1["issue"]["choices"][0]["input_id"]], "fuzzy" => true}
		logic_control_rule["result"] = nil

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :logic_control_rule => logic_control_rule
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 1
		assert_equal ErrorEnum::LOGIC_CONTROL_RULE_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 0
		assert_equal true.to_s, @response.body
		get :index, :format => :json, :survey_id => survey_id
		logic_control = JSON.parse(@response.body)
		assert_equal 0, logic_control.length
		sign_out
	end
end
