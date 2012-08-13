require 'test_helper'

class QualityControlQuestionsControllerTest < ActionController::TestCase

	test "should create quality control question" do
		clear(User, Survey, QualityControlQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :quality_control_type => 1, :question_type => 0, :question_number => -1
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 3, :question_type => 0, :question_number => -1
		assert_equal ErrorEnum::WRONG_QUALITY_CONTROL_TYPE.to_s, @response.body
		sign_out

		# create an objective quality control question
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 1, :question_type => 0, :question_number => -1
		retval = JSON.parse(@response.body)
		assert_equal 2, retval.length
		assert_equal 1, retval[1]["question_id"].length
		assert_equal retval[0]["_id"], retval[1]["question_id"][0]
		assert_equal false, retval[1]["answer_content"]["fuzzy"]
		assert_equal QualityControlTypeEnum::OBJECTIVE, retval[1]["quality_control_type"]
		sign_out

		# create matching quality control questions
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 2, :question_type => 0, :question_number => 3
		retval = JSON.parse(@response.body)
		assert_equal 4, retval.length
		assert_equal retval[0]["_id"], retval[3]["question_id"][0]
		assert_equal retval[1]["_id"], retval[3]["question_id"][1]
		assert_equal retval[2]["_id"], retval[3]["question_id"][2]
		assert_equal QualityControlTypeEnum::MATCHING, retval[3]["quality_control_type"]
		sign_out
	end

end
