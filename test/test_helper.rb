ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'securerandom'

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

	def init_lisa
		lisa = FactoryGirl.build(:lisa)
		lisa.save
		return lisa
	end

	def init_polly
		polly = FactoryGirl.build(:polly)
		polly.save
		return polly
	end

	def init_admin
		admin = FactoryGirl.build(:admin)
		admin.save
		return admin
	end

	def init_survey_auditor
		survey_auditor = FactoryGirl.build(:survey_auditor)
		survey_auditor.save
		return survey_auditor
	end

	def init_answer_auditor
		answer_auditor = FactoryGirl.build(:answer_auditor)
		answer_auditor.save
		return answer_auditor
	end

	def init_entry_clerk
		entry_clerk = FactoryGirl.build(:entry_clerk)
		entry_clerk.save
		return entry_clerk
	end

	def init_interviewer
		interviewer = FactoryGirl.build(:interviewer)
		interviewer.save
		return interviewer
	end

	def set_as_admin(user)
		user.role = user.role | 16
		user.save
	end

	def create_new_visitor_user
		old_controller = @controller
		@controller = RegistrationsController.new
		post :create_new_visitor_user, :format => :json
		result = JSON.parse(@response.body)
		@controller = old_controller
		return result["value"]
	end

	def sign_in(email, password)
		old_controller = @controller
		@controller = SessionsController.new
		post :create, :format => :json, :user => {"email_username" => email, "password" => password}
		result = JSON.parse(@response.body)
		@controller = old_controller
		return result["value"]["auth_key"]
	end

	def sign_out(auth_key)
		old_controller = @controller
		@controller = SessionsController.new
		get :destroy, :auth_key => auth_key
		@controller = old_controller
	end

	def create_closed_survey(user = nil)
		closed_survey = FactoryGirl.build(:closed_survey)
		closed_survey.save
		if !user.nil?
			user.surveys << closed_survey
		end
		return closed_survey._id.to_s
	end

	def create_under_review_survey(user = nil)
		under_review_survey = FactoryGirl.build(:under_review_survey)
		under_review_survey.save
		if !user.nil?
			user.surveys << under_review_survey
		end
		return under_review_survey._id.to_s
	end

	def create_paused_survey(user = nil)
		paused_survey = FactoryGirl.build(:paused_survey)
		paused_survey.save
		if !user.nil?
			user.surveys << paused_survey
		end
		return paused_survey._id.to_s
	end

	def create_published_survey(user = nil)
		published_survey = FactoryGirl.build(:published_survey)
		published_survey.save
		if !user.nil?
			user.surveys << published_survey
		end
		return published_survey._id.to_s
	end

	def create_survey(email, password)
		auth_key = sign_in(email, password)
		old_controller = @controller
		@controller = SurveysController.new
		get :new, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj, :auth_key => auth_key
		@controller = old_controller
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		sign_out(auth_key)
		return survey_obj["_id"]
	end

	def set_survey_published(survey_id, operator, survey_auditor)
		survey = Survey.find_by_id(survey_id)
		survey.submit("", operator)
		survey.publish("", survey_auditor)
	end

	def set_survey_random_quality_control_questions(survey_id)
		survey = Survey.find_by_id(survey_id)
		survey.quality_control_questions_type = 2
		survey.save
	end

	def update_survey_access_control_setting(email, password, survey_id, access_control_setting)
		auth_key = sign_in(email, password)
		old_controller = @controller
		@controller = SurveysController.new
		put :update_access_control_setting, :format => :json, :id => survey_id, :access_control_setting => access_control_setting, :auth_key => auth_key
		result = JSON.parse(@response.body)
		@controller = old_controller
		sign_out(auth_key)
	end

	def get_survey_style_setting(email, password, survey_id)
		auth_key = sign_in(email, password)
		old_controller = @controller
		@controller = SurveysController.new
		get :show_style_setting, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		@controller = old_controller
		sign_out(auth_key)
		return result
	end

	def update_survey_style_setting(email, password, survey_id, style_setting)
		auth_key = sign_in(email, password)
		old_controller = @controller
		@controller = SurveysController.new
		put :update_style_setting, :format => :json, :id => survey_id, :style_setting => style_setting, :auth_key => auth_key
		result = JSON.parse(@response.body)
		@controller = old_controller
		sign_out(auth_key)
	end

	def get_survey_obj(email, password, survey_id)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = SurveysController.new
		get :show, :format => :json, :id => survey_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		survey_obj = result["value"]
		@controller = old_controller
		sign_out(auth_key)
		return survey_obj
	end

	def insert_page(email, password, survey_id, page_index, page_name)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = PagesController.new
		post :create, :format => :json, :survey_id => survey_id, :page_index => page_index, :page_name => page_name, :auth_key => auth_key
		@controller = old_controller
		sign_out(auth_key)
	end

	def remove_page(email, password, survey_id, page_index)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = PagesController.new
		delete :destroy, :format => :json, :survey_id => survey_id, :id => page_index, :auth_key => auth_key
		result = JSON.parse(@response.body)
		@controller = old_controller
		sign_out(auth_key)
	end

	def create_question(email, password, survey_id, page_index, question_id, question_type)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuestionsController.new
		post :create, :format => :json, :survey_id => survey_id, :page_index => page_index, :question_id => question_id, :question_type => question_type, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj = result["value"]
		@controller = old_controller
		sign_out(auth_key)
		return question_obj["_id"]
	end

	def create_choice_question_with_choices(email, password, survey_id, page_index, question_id, question_type)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuestionsController.new
		post :create, :format => :json, :survey_id => survey_id, :page_index => page_index, :question_id => question_id, :question_type => question_type, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj = result["value"]
		question_obj["issue"]["min_choice"] = 2
		question_obj["issue"]["max_choice"] = 4
		question_obj["issue"]["items"] << {"id" => SecureRandom.uuid, "content" => "first choice content", "has_input" => false, "is_exclusive" => false}
		question_obj["issue"]["items"] << {"id" => SecureRandom.uuid, "content" => "second choice content", "has_input" => false, "is_exclusive" => false}
		question_obj["issue"]["items"] << {"id" => SecureRandom.uuid, "content" => "third choice content", "has_input" => false, "is_exclusive" => false}
		put :update, :format => :json, :survey_id => survey_id, :id => question_obj["_id"], :question => question_obj, :auth_key => auth_key
		@controller = old_controller
		sign_out(auth_key)
		return question_obj["_id"]
	end

	def show_question(email, password, survey_id, question_id)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuestionsController.new
		get :show, :format => :json, :survey_id => survey_id, :id => question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj = result["value"]
		@controller = old_controller
		sign_out(auth_key)
		return question_obj
	end

	def show_survey(email, password, survey_id)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = SurveysController.new
		get :show, :format => :json, :id => survey_id, :auth_key => auth_key
		survey_obj = JSON.parse(@response.body)
		@controller = old_controller
		sign_out(auth_key)
		return survey_obj
	end

	def create_short_survey_page_question(email, password)
		survey_id = create_survey(email, Encryption.decrypt_password(password))
	
		remove_page(email, password, survey_id, 0)
		insert_page(email, password, survey_id, -1, "first page")

		q1 = create_question(email, password, survey_id, 0, -1, 0)
		q2 = create_question(email, password, survey_id, 0, -1, 8)
		q3 = create_question(email, password, survey_id, 0, -1, 11)

		return [survey_id, [[q1, q2, q3]]]
	end

	def create_survey_page_question(email, password)
		survey_id = create_survey(email, Encryption.decrypt_password(password))
	
		remove_page(email, password, survey_id, 0)
		insert_page(email, password, survey_id, -1, "first page")
		insert_page(email, password, survey_id, 0, "second page")
		insert_page(email, password, survey_id, 0, "third page")
		insert_page(email, password, survey_id, 0, "fouth page")

		q1 = create_question(email, password, survey_id, 0, -1, 0)
		q2 = create_question(email, password, survey_id, 0, -1, 8)
		q3 = create_question(email, password, survey_id, 0, -1, 11)
		q4 = create_question(email, password, survey_id, 1, -1, 12)
		q5 = create_question(email, password, survey_id, 2, -1, 1)
		q6 = create_question(email, password, survey_id, 2, -1, 13)
		q7 = create_question(email, password, survey_id, 2, -1, 9)
		q8 = create_question(email, password, survey_id, 2, -1, 8)
		q9 = create_question(email, password, survey_id, 3, -1, 10)
		q10 = create_question(email, password, survey_id, 3, -1, 14)

		return [survey_id, [[q1, q2, q3], [q4], [q5, q6, q7, q8], [q9, q10]]]
	end

	def get_question_obj(email, password, survey_id, question_id)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuestionsController.new
		get :show, :format => :json, :survey_id => survey_id, :id => question_id, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj = result["value"]
		@controller = old_controller
		sign_out(auth_key)
		return question_obj
	end

	def generate_group_members
		members = []
		("a".."z").to_a.each do |char|
			member = {"email" => "#{char}@#{char}.com", "mobile" => "123456789"}
			members << member
		end
		return members
	end

	def create_materials(email, password)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = MaterialsController.new
		post :create, :format => :json, :material => {"material_type" => 1, "location" => "location_1", "title" => "title_1"}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_1 = result["value"]["_id"]
		post :create, :format => :json, :material => {"material_type" => 1, "location" => "location_2", "title" => "title_2"}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_2 = result["value"]["_id"]
		post :create, :format => :json, :material => {"material_type" => 1, "location" => "location_3", "title" => "title_3"}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_3 = result["value"]["_id"]
		post :create, :format => :json, :material => {"material_type" => 2, "location" => "location_4", "title" => "title_4"}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_4 = result["value"]["_id"]
		post :create, :format => :json, :material => {"material_type" => 2, "location" => "location_5", "title" => "title_5"}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_5 = result["value"]["_id"]
		post :create, :format => :json, :material => {"material_type" => 4, "location" => "location_6", "title" => "title_6"}, :auth_key => auth_key
		result = JSON.parse(@response.body)
		material_id_6 = result["value"]["_id"]
		@controller = old_controller
		sign_out(auth_key)
		return [material_id_1, material_id_2, material_id_3, material_id_4, material_id_5, material_id_6]
	end

	def create_template_question(email, password, question_type)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = Admin::TemplateQuestionsController.new
		post :create, :format => :json, :question_type => question_type, :auth_key => auth_key
		result = JSON.parse(@response.body)
		question_obj = result["value"]
		@controller = old_controller
		sign_out(auth_key)
		return question_obj["_id"]
	end

	def create_quality_control_question(email, password, quality_control_type, question_type, question_number)
		auth_key = sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = Admin::QualityControlQuestionsController.new
		post :create, :format => :json, :quality_control_type => quality_control_type, :question_type => question_type, :question_number => question_number, :auth_key => auth_key
		result = JSON.parse(@response.body)
		retval = result["value"]
		@controller = old_controller
		sign_out(auth_key)
		return retval[0]["_id"]
	end
end

require 'rubygems'
require 'spork'

#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
	ENV["RAILS_ENV"] = "test"
	require File.expand_path('../../config/environment', __FILE__)

	require "minitest/autorun"
	require "minitest/rails"
	MiniTest::Rails.override_testunit!
	# Uncomment if you want Capybara in accceptance/integration tests
	# require "minitest/rails/capybara"

	# Uncomment if you want awesome colorful output
	# require "minitest/pride"

	class MiniTest::Rails::ActiveSupport::TestCase
	  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
	  # fixtures :all

	  # Add more helper methods to be used by all tests here...
	end
  
end

Spork.each_run do
  # This code will be run each time you run your specs.

end
