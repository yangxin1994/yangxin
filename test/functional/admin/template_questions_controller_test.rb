require 'test_helper'

class Admin::TemplateQuestionsControllerTest < ActionController::TestCase

	test "should create template question" do
		clear(User, Survey, TemplateQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :question_type => 0
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :question_type => 0
		retval = JSON.parse(@response.body)
		assert_equal "", retval["attribute_name"]
		sign_out
	end

	test "should update template question" do
		clear(User, Survey, TemplateQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :question_type => 0
		template_question_obj = JSON.parse(@response.body)
		assert_equal "", template_question_obj["attribute_name"]
		sign_out

		template_question_obj["attribute_name"] = "gender"

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => "wrong template question id", :question => template_question_obj
		assert_equal ErrorEnum::TEMPLATE_QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => template_question_obj["_id"], :question => template_question_obj
		updated_template_question_obj = JSON.parse(@response.body)
		assert_equal "gender", updated_template_question_obj["attribute_name"]
		sign_out
	end

	test "should list template question" do
		clear(User, Survey, TemplateQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :question_type => 0
		t_q_1 = JSON.parse(@response.body)
		t_q_1["attribute_name"] = "gender"
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :question_type => 0
		t_q_2 = JSON.parse(@response.body)
		t_q_2["attribute_name"] = "age"
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => t_q_1["_id"], :question => t_q_1
		updated_template_question_obj = JSON.parse(@response.body)
		assert_equal "gender", updated_template_question_obj["attribute_name"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => t_q_2["_id"], :question => t_q_2
		updated_template_question_obj = JSON.parse(@response.body)
		assert_equal "age", updated_template_question_obj["attribute_name"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json
		template_question_obj_ary = JSON.parse(@response.body)
		assert_equal 2, template_question_obj_ary.length
		assert_equal "gender", template_question_obj_ary[0]["attribute_name"]
		assert_equal "age", template_question_obj_ary[1]["attribute_name"]
		sign_out
	end

	test "should destroy template question" do
		clear(User, Survey, TemplateQuestion)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :question_type => 0
		t_q_1 = JSON.parse(@response.body)
		t_q_1["attribute_name"] = "gender"
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :question_type => 0
		t_q_2 = JSON.parse(@response.body)
		t_q_2["attribute_name"] = "age"
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => t_q_1["_id"], :question => t_q_1
		updated_template_question_obj = JSON.parse(@response.body)
		assert_equal "gender", updated_template_question_obj["attribute_name"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		put :update, :format => :json, :id => t_q_2["_id"], :question => t_q_2
		updated_template_question_obj = JSON.parse(@response.body)
		assert_equal "age", updated_template_question_obj["attribute_name"]
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => "wrong template question id"
		assert_equal ErrorEnum::TEMPLATE_QUESTION_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :id => t_q_1["_id"]
		assert_equal true.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json
		template_question_obj_ary = JSON.parse(@response.body)
		assert_equal 1, template_question_obj_ary.length
		assert_equal "age", template_question_obj_ary[0]["attribute_name"]
		sign_out
	end
end
