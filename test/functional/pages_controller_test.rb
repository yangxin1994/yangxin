require 'test_helper'

class PagesControllerTest < ActionController::TestCase

	test "should create page" do
		clear(User, Survey, Question)
		jesse = init_jesse
		oliver = init_oliver

		survey_id = create_survey(jesse.email, Encryption.decrypt_password(jesse.password))
		
		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :survey_id => survey_id, :page_index => -1
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out
	end

	def create_survey(email, password)
		sign_in(email, password)
		old_controller = @controller
		@controller = SurveysController.new
		get :new, :format => :json
		survey_obj = JSON.parse(@response.body)
		post :save_meta_data, :format => :json, :survey => survey_obj
		@controller = old_controller
		survey_obj = JSON.parse(@response.body)
		sign_out
		return survey_obj["survey_id"]
	end
end
