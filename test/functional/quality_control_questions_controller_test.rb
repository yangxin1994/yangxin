require 'test_helper'

class QualityControlQuestionsControllerTest < ActionController::TestCase

	test "should create quality control question" do
		clear(User, Survey, QualityControlQuestion, QualityControlQuestionAnswer, MatchingQuestion)
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

	test "should update quality control question" do
		clear(User, Survey, QualityControlQuestion, QualityControlQuestionAnswer, MatchingQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		# create an objective quality control question
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 1, :question_type => 0, :question_number => -1
		retval = JSON.parse(@response.body)
		objective_question_obj = retval[0]
		sign_out

		objective_question_obj["issue"]["min_choice"] = 2
		objective_question_obj["issue"]["max_choice"] = 4
		objective_question_obj["issue"]["is_rand"] = true
		objective_question_obj["issue"]["non_exist_attr"] = 1
		objective_question_obj["issue"]["choices"] << {"content" => "first choice content", "has_input" => false, "is_exclusive" => false, "non_exist_attr" => 1}

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => "wrong quality control question id", :question => objective_question_obj
		assert_equal ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => objective_question_obj["_id"], :question => objective_question_obj
		updated_question_obj = JSON.parse(@response.body)
		sign_out
		assert_equal objective_question_obj["issue"]["min_choice"], updated_question_obj["issue"]["min_choice"]
		assert_equal objective_question_obj["issue"]["max_choice"], updated_question_obj["issue"]["max_choice"]
		assert_equal objective_question_obj["issue"]["is_rand"], updated_question_obj["issue"]["is_rand"]
		assert_equal objective_question_obj["issue"]["choices"][0]["content"], updated_question_obj["issue"]["choices"][0]["content"]
		assert_equal nil, updated_question_obj["issue"]["non_exist_attr"]
	end

	test "should show quality control question" do
		clear(User, Survey, QualityControlQuestion, QualityControlQuestionAnswer, MatchingQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		# create an objective quality control question
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 1, :question_type => 0, :question_number => -1
		retval = JSON.parse(@response.body)
		objective_question_obj = retval[0]
		sign_out

		# create matching quality control questions
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 2, :question_type => 0, :question_number => 3
		retval = JSON.parse(@response.body)
		matching_question_obj = retval[0]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => "wrong quality control question id"
		assert_equal ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => objective_question_obj["_id"]
		retval = JSON.parse(@response.body)
		assert_equal 2, retval.length
		assert_equal 1, retval[1]["question_id"].length
		assert_equal objective_question_obj["_id"], retval[1]["question_id"][0]
		assert_equal objective_question_obj["_id"], retval[0]["_id"]
		assert_equal false, retval[1]["answer_content"]["fuzzy"]
		assert_equal QualityControlTypeEnum::OBJECTIVE, retval[1]["quality_control_type"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :id => matching_question_obj["_id"]
		retval = JSON.parse(@response.body)
		assert_equal 4, retval.length
		assert_equal retval[0]["_id"], retval[3]["question_id"][0]
		assert_equal retval[1]["_id"], retval[3]["question_id"][1]
		assert_equal retval[2]["_id"], retval[3]["question_id"][2]
		assert_equal QualityControlTypeEnum::MATCHING, retval[3]["quality_control_type"]
		sign_out
	end

	test "should list quality control question" do
		clear(User, Survey, QualityControlQuestion, QualityControlQuestionAnswer, MatchingQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		# create an objective quality control question
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 1, :question_type => 0, :question_number => -1
		retval = JSON.parse(@response.body)
		objective_question_obj = retval[0]
		sign_out

		# create matching quality control questions
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 2, :question_type => 0, :question_number => 3
		retval = JSON.parse(@response.body)
		matching_question_obj = retval[0]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :quality_control_type => 1
		retval = JSON.parse(@response.body)
		assert_equal Array, retval["objective_questions"].class
		assert_equal 1, retval["objective_questions"].length
		assert_equal objective_question_obj["_id"], retval["objective_questions"][0]["_id"]
		assert_equal Array, retval["matching_questions"].class
		assert_equal 0, retval["matching_questions"].length
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :quality_control_type => 2
		retval = JSON.parse(@response.body)
		assert_equal Array, retval["objective_questions"].class
		assert_equal 0, retval["objective_questions"].length
		assert_equal Array, retval["matching_questions"].class
		assert_equal 1, retval["matching_questions"].length
		assert_equal 3, retval["matching_questions"][0].length
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :quality_control_type => 3
		retval = JSON.parse(@response.body)
		assert_equal Array, retval["objective_questions"].class
		assert_equal 1, retval["objective_questions"].length
		assert_equal objective_question_obj["_id"], retval["objective_questions"][0]["_id"]
		assert_equal Array, retval["matching_questions"].class
		assert_equal 1, retval["matching_questions"].length
		assert_equal 3, retval["matching_questions"][0].length
		sign_out
	end

	test "should update quality control question answer" do
		clear(User, Survey, QualityControlQuestion, QualityControlQuestionAnswer, MatchingQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		# create an objective quality control question
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 1, :question_type => 0, :question_number => -1
		retval = JSON.parse(@response.body)
		objective_question_answer = retval[1]
		objective_question_obj = retval[0]
		sign_out

		# create matching quality control questions
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 2, :question_type => 0, :question_number => 3
		retval = JSON.parse(@response.body)
		matching_question_answer = retval[-1]
		matching_question_obj_1 = retval[0]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update_answer, :format => :json, :id => "wrong quality control question id", :quality_control_type => 1, :answer => objective_question_answer 
		assert_equal ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update_answer, :format => :json, :id => objective_question_obj["_id"], :quality_control_type => 4, :answer => objective_question_answer 
		assert_equal ErrorEnum::WRONG_QUALITY_CONTROL_TYPE.to_s, @response.body
		sign_out

		# update objective question answer
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update_answer, :format => :json, :id => objective_question_obj["_id"], :quality_control_type => 1, :answer => objective_question_answer 
		assert_equal true.to_s, @response.body
		sign_out

		# update matching question answer
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update_answer, :format => :json, :id => matching_question_obj_1["_id"], :quality_control_type => 2, :answer => matching_question_answer 
		assert_equal true.to_s, @response.body
		sign_out
	end

	test "should destroy quality control question" do
		clear(User, Survey, QualityControlQuestion, QualityControlQuestionAnswer, MatchingQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		# create an objective quality control question
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 1, :question_type => 0, :question_number => -1
		retval = JSON.parse(@response.body)
		objective_question_obj = retval[0]
		sign_out

		# create matching quality control questions
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :quality_control_type => 2, :question_type => 0, :question_number => 3
		retval = JSON.parse(@response.body)
		matching_question_obj_1 = retval[0]
		sign_out
			
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong quality control question id"
		assert_equal ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => objective_question_obj["_id"]
		assert_equal true.to_s, @response.body
		get :index, :format => :json, :quality_control_type => 3
		retval = JSON.parse(@response.body)
		assert_equal Array, retval["objective_questions"].class
		assert_equal 0, retval["objective_questions"].length
		assert_equal 1, retval["matching_questions"].length
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => matching_question_obj_1["_id"]
		assert_equal true.to_s, @response.body
		get :index, :format => :json, :quality_control_type => 3
		retval = JSON.parse(@response.body)
		assert_equal Array, retval["objective_questions"].class
		assert_equal 0, retval["objective_questions"].length
		assert_equal 0, retval["matching_questions"].length
		sign_out
	end
end
