require 'test_helper'

class PagesControllerTest < ActionController::TestCase

	test "should create page" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => -1, :page_name => "new page name"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :page_name => "new page name"
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => "wrong survey id", :page_index => -1, :page_name => "new page name"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => -1, :page_name => "new page name"
		assert_equal true.to_s, @response.body
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :page_name => "new page name"
		post :create, :format => :json, :survey_id => survey_id, :page_index => 0, :page_name => "new page name"
		sign_out

		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal 3, survey_obj["pages"].length
	end

	test "should show page" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => survey_id, :id => 10
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => "wrong survey id", :id => 0
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :show, :format => :json, :survey_id => survey_id, :id => 0
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :survey_id => survey_id, :id => 0
		page_obj = JSON.parse(@response.body)
		assert_equal pages[0].length, page_obj["questions"].length
		assert_equal pages[0][0], page_obj["questions"][0]["_id"]
		assert_equal pages[0][1], page_obj["questions"][1]["_id"]
		assert_equal pages[0][2], page_obj["questions"][2]["_id"]
		get :show, :format => :json, :survey_id => survey_id, :id => 1
		page_obj = JSON.parse(@response.body)
		assert_equal pages[1].length, page_obj["questions"].length
		assert_equal pages[1][0], page_obj["questions"][0]["_id"]
		sign_out
	end

	test "should update page" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 10, :page_name => "new page name"
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => "wrong survey id", :id => 0, :page_name => "new page name"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :page_name => "new page name"
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :survey_id => survey_id, :id => 0, :page_name => "new page name"
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :survey_id => survey_id, :id => 0
		page_obj = JSON.parse(@response.body)
		assert_equal "new page name", page_obj["name"]
		sign_out
	end

	test "should delete page" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => "wrong survey id", :id => 0
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 10
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :survey_id => survey_id, :id => 0
		assert_equal true.to_s, @response.body
		sign_out
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal survey_obj["pages"].length, pages.length - 1
		assert_equal survey_obj["pages"][0]["questions"].length, pages[1].length
	end

	test "should combine pages" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :combine, :format => :json, :survey_id => survey_id, :page_index_1 => 1, :page_index_2 => 10
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :combine, :format => :json, :survey_id => "wrong survey id", :page_index_1 => 1, :page_index_2 => 3
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :combine, :format => :json, :survey_id => survey_id, :page_index_1 => 1, :page_index_2 => 3
		assert_equal true.to_s, @response.body
		sign_out
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal survey_obj["pages"].length, pages.length - 2
		assert_equal survey_obj["pages"][0]["questions"].length, pages[0].length
		assert_equal survey_obj["pages"][1]["questions"].length, pages[1].length + pages[2].length + pages[3].length
	end

	test "should move page" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :move, :format => :json, :survey_id => survey_id, :page_index_1 => 0, :page_index_2 => 10
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :move, :format => :json, :survey_id => "wrong survey id", :page_index_1 => 0, :page_index_2 => 3
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :move, :format => :json, :survey_id => survey_id, :page_index_1 => 0, :page_index_2 => 3
		assert_equal true.to_s, @response.body
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal survey_obj["pages"].length, pages.length
		assert_equal survey_obj["pages"][0]["questions"].length, pages[1].length
		assert_equal survey_obj["pages"][1]["questions"].length, pages[2].length
		assert_equal survey_obj["pages"][2]["questions"].length, pages[3].length
		assert_equal survey_obj["pages"][3]["questions"].length, pages[0].length
		sign_out
	end

	test "should clone page" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id, pages = *create_survey_page_question(jesse.email, jesse.password)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clone, :format => :json, :survey_id => survey_id, :page_index_1 => 0, :page_index_2 => 10
		assert_equal ErrorEnum::OVERFLOW.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clone, :format => :json, :survey_id => "wrong survey id", :page_index_1 => 0, :page_index_2 => 3
		assert_equal ErrorEnum::SURVEY_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :clone, :format => :json, :survey_id => survey_id, :page_index_1 => 0, :page_index_2 => 3
		page_obj = JSON.parse(@response.body)
		sign_out
		survey_obj = get_survey_obj(jesse.email, jesse.password, survey_id)
		assert_equal survey_obj["pages"][0]["questions"].length, page_obj["questions"].length
		assert_equal pages.length + 1, survey_obj["pages"].length
		assert_equal survey_obj["pages"][0]["questions"].length,survey_obj["pages"][4]["questions"].length
	end
end
