ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...

	def clear(*models)
		models.each do |model|
			model.all.each do |instance|
				instance.destroy
			end
		end
	end

	def remove_user(email)
		user = User.find_by_email(email)
		user.destroy if user.class == User
	end

	def activate_user(email)
		activate_info = {"email" => email, "time" => Time.now.to_i}
		User.activate(activate_info)
	end

	def remove_survey(survey_id)
		survey = Survey.find_by_id(survey_id.to_s)
		survey.destroy if survey.class == Survey
	end

	def init_new_user
		new_user = FactoryGirl.build(:new_user)
		new_user.save
		return new_user
	end

	def init_activated_user
		activated_user = FactoryGirl.build(:activated_user)
		activated_user.save
		return activated_user
	end

	def init_jesse
		jesse = FactoryGirl.build(:jesse)
		jesse.save
		return jesse
	end

	def init_oliver
		oliver = FactoryGirl.build(:oliver)
		oliver.save
		return oliver
	end




	def sign_in(email, password)
		old_controller = @controller
		@controller = SessionsController.new
		post :create, :format => :json, :user => {"email" => email, "password" => password}
		@controller = old_controller
	end

	def sign_out
		old_controller = @controller
		@controller = SessionsController.new
		get :destroy
		@controller = old_controller
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

	def get_survey_obj(email, password, survey_id)
		sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = SurveysController.new
		get :show, :format => :json, :id => survey_id
		survey_obj = JSON.parse(@response.body)
		@controller = old_controller
		sign_out
		return survey_obj
	end

	def insert_page(email, password, survey_id, page_index)
		sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = PagesController.new
		post :create, :format => :json, :survey_id => survey_id, :page_index => page_index
		@controller = old_controller
		sign_out
	end

	def create_question(email, password, survey_id, page_index, question_id, question_type)
		sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuestionsController.new
		post :create, :format => :json, :survey_id => survey_id, :page_index => page_index, :question_id => question_id, :question_type => question_type
		question_obj = JSON.parse(@response.body)
		@controller = old_controller
		sign_out
		return question_obj["question_id"]
	end
end
