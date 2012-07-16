require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase

	test "should create question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		insert_page(jesse.email, jesse.password, survey_id, -1, "first page")
		insert_page(jesse.email, jesse.password, survey_id, 0, "second page")

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => "wrong survey id", :page_index => 0, :question_id => -1, :question_type => 0
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 2, :question_id => -1, :question_type => 0
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => "wrong question id", :question_type => 0
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => 0
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => 200
		assert_equal ErrorEnum::WRONG_QUESTION_TYPE.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => 0
		question_obj_1 = JSON.parse(@response.body)
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => 10
		question_obj_3 = JSON.parse(@response.body)
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => question_obj_1["_id"], :question_type => 12
		question_obj_2 = JSON.parse(@response.body)
		post :create, :format => :json, :survey_id => survey_id, :page_index => 1, :question_id => -1, :question_type => 15
		question_obj_4 = JSON.parse(@response.body)
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal 3, survey_obj["pages"][0]["questions"].length
		assert_equal 1, survey_obj["pages"][1]["questions"].length
		assert_equal question_obj_1["_id"], survey_obj["pages"][0]["questions"][0]
		assert_equal question_obj_2["_id"], survey_obj["pages"][0]["questions"][1]
		assert_equal question_obj_3["_id"], survey_obj["pages"][0]["questions"][2]
		assert_equal question_obj_4["_id"], survey_obj["pages"][1]["questions"][0]
		sign_out
	end

	test "should update question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)
		question_obj = get_question_obj(jesse.email, jesse.password, survey_id, pages[0][0])
		question_obj["issue"]["min_choice"] = 2
		question_obj["issue"]["max_choice"] = 4
		question_obj["issue"]["is_rand"] = true
		question_obj["issue"]["non_exist_attr"] = 1
		question_obj["issue"]["choices"] << {"content" => "first choice content", "has_input" => false, "is_exclusive" => false, "non_exist_attr" => 1}

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => "wrong survey id", :id => pages[0][0], :question => question_obj
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => "wrong question id", :question => question_obj
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => pages[0][0], :question => question_obj
		updated_question_obj = JSON.parse(@response.body)
		sign_out
		assert_equal question_obj["issue"]["min_choice"], updated_question_obj["issue"]["min_choice"]
		assert_equal question_obj["issue"]["max_choice"], updated_question_obj["issue"]["max_choice"]
		assert_equal question_obj["issue"]["is_rand"], updated_question_obj["issue"]["is_rand"]
		assert_equal question_obj["issue"]["choices"][0]["content"], updated_question_obj["issue"]["choices"][0]["content"]
		assert_equal nil, updated_question_obj["issue"]["non_exist_attr"]
	end

	test "should show question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => "wrong survey id", :id => pages[0][1]
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => survey_id, :id => "wrong question id"
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => survey_id, :id => pages[0][1]
		question_obj = JSON.parse(@response.body)
		assert_equal pages[0][1], question_obj["_id"]
		sign_out
	end

	test "should delete question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => "wrong survey id", :id => pages[0][1]
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => "wrong question id"
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => pages[0][1]
		assert_equal true.to_s, @response.body
		sign_out
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal pages.length, survey_obj["pages"].length
		assert_equal pages[0].length - 1, survey_obj["pages"][0]["questions"].length
		assert_equal pages[0][0], survey_obj["pages"][0]["questions"][0]
		assert_equal pages[0][2], survey_obj["pages"][0]["questions"][1]
	end	

	test "should move question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :move, :format => :json, :survey_id => "wrong survey id", :page_index => 2, :question_id_1 => pages[2][1], :question_id_2 => pages[2][3]
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :move, :format => :json, :survey_id => survey_id, :page_index => 10, :question_id_1 => pages[2][1], :question_id_2 => pages[2][3]
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :move, :format => :json, :survey_id => survey_id, :page_index => 2, :question_id_1 => "wrong question id", :question_id_2 => pages[2][3]
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :move, :format => :json, :survey_id => survey_id, :page_index => 2, :question_id_1 => pages[2][1], :question_id_2 => pages[2][3]
		assert_equal true.to_s, @response.body
		sign_out
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal pages[2][0], survey_obj["pages"][2]["questions"][0]
		assert_equal pages[2][2], survey_obj["pages"][2]["questions"][1]
		assert_equal pages[2][3], survey_obj["pages"][2]["questions"][2]
		assert_equal pages[2][1], survey_obj["pages"][2]["questions"][3]
	end

	test "should clone question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)
		question_obj = get_question_obj(jesse.email, jesse.password, survey_id, pages[0][0])
		question_obj["issue"]["min_choice"] = 2
		question_obj["issue"]["max_choice"] = 4
		question_obj["issue"]["is_rand"] = true
		question_obj["issue"]["choices"] << {"content" => "first choice content", "has_input" => false, "is_exclusive" => false, "non_exist_attr" => 1}
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => pages[0][0], :question => question_obj
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clone, :format => :json, :survey_id => "wrong survey id", :page_index => 2, :question_id_1 => pages[0][0], :question_id_2 => -1
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clone, :format => :json, :survey_id => survey_id, :page_index => 10, :question_id_1 => pages[0][0], :question_id_2 => -1
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clone, :format => :json, :survey_id => survey_id, :page_index => 2, :question_id_1 => "wrong question id", :question_id_2 => -1
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clone, :format => :json, :survey_id => survey_id, :page_index => 2, :question_id_1 => pages[0][0], :question_id_2 => -1
		cloned_question_obj = JSON.parse(@response.body)
		sign_out
		assert_equal question_obj["issue"]["min_choice"], cloned_question_obj["issue"]["min_choice"]
		assert_equal question_obj["issue"]["max_choice"], cloned_question_obj["issue"]["max_choice"]
		assert_equal question_obj["issue"]["is_rand"], cloned_question_obj["issue"]["is_rand"]
		assert_equal question_obj["issue"]["choices"][0]["content"], cloned_question_obj["issue"]["choices"][0]["content"]
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		cloned_question_obj = get_question_obj(jesse.email, jesse.password, survey_id, survey_obj["pages"][2]["questions"][0])
		assert_equal question_obj["issue"]["min_choice"], cloned_question_obj["issue"]["min_choice"]
		assert_equal question_obj["issue"]["max_choice"], cloned_question_obj["issue"]["max_choice"]
		assert_equal question_obj["issue"]["is_rand"], cloned_question_obj["issue"]["is_rand"]
		assert_equal question_obj["issue"]["choices"][0]["content"], cloned_question_obj["issue"]["choices"][0]["content"]
	end
end