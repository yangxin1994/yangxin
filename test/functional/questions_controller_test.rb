require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase

	test "should create question" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))

		insert_page(jesse.email, jesse.password, survey_id, -1)
		insert_page(jesse.email, jesse.password, survey_id, 0)

		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => "wrong survey id", :page_index => 0, :question_id => -1, :question_type => "ChoiceQuestion"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 2, :question_id => -1, :question_type => "ChoiceQuestion"
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => "wrong question type", :question_type => "ChoiceQuestion"
		assert_equal ErrorEnum::QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => "ChoiceQuestion"
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => "WrongQuestionType"
		assert_equal ErrorEnum::WRONG_QUESTION_TYPE.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => "ChoiceQuestion"
		question_obj_1 = JSON.parse(@response.body)
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => -1, :question_type => "BlankQuestion"
		question_obj_3 = JSON.parse(@response.body)
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :question_id => question_obj_1["question_id"], :question_type => "SortQuestion"
		question_obj_2 = JSON.parse(@response.body)
		post :create, :format => :json, :survey_id => survey_id, :page_index => 1, :question_id => -1, :question_type => "RankQuestion"
		question_obj_4 = JSON.parse(@response.body)
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal 3, survey_obj["pages"][0].length
		assert_equal 1, survey_obj["pages"][1].length
		assert_equal question_obj_1["question_id"], survey_obj["pages"][0][0]
		assert_equal question_obj_2["question_id"], survey_obj["pages"][0][1]
		assert_equal question_obj_3["question_id"], survey_obj["pages"][0][2]
		assert_equal question_obj_4["question_id"], survey_obj["pages"][1][0]
		sign_out


	end

end
