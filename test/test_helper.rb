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

	def init_lisa
		lisa = FactoryGirl.build(:lisa)
		lisa.save
		return lisa
	end

	def init_survey_auditor
		survey_auditor = FactoryGirl.build(:survey_auditor)
		survey_auditor.save
		return survey_auditor
	end

	def set_as_admin(user)
		user.role = 1
		user.save
	end


	def sign_in(email, password)
		old_controller = @controller
		@controller = SessionsController.new
		post :create, :format => :json, :user => {"email_username" => email, "password" => password}
		@controller = old_controller
	end

	def sign_out
		old_controller = @controller
		@controller = SessionsController.new
		get :destroy
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
		sign_in(email, password)
		old_controller = @controller
		@controller = SurveysController.new
		get :new, :format => :json
		survey_obj = JSON.parse(@response.body)
		post :save_meta_data, :format => :json, :id => survey_obj["_id"], :survey => survey_obj
		@controller = old_controller
		survey_obj = JSON.parse(@response.body)
		sign_out
		return survey_obj["_id"]
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

	def insert_page(email, password, survey_id, page_index, page_name)
		sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = PagesController.new
		post :create, :format => :json, :survey_id => survey_id, :page_index => page_index, :page_name => page_name
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
		return question_obj["_id"]
	end

	def create_survey_page_question(email, password)
		survey_id = create_survey(email, Encryption.decrypt_password(password))
	
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
		sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = QuestionsController.new
		get :show, :format => :json, :survey_id => survey_id, :id => question_id
		question_obj = JSON.parse(@response.body)
		@controller = old_controller
		sign_out
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
		sign_in(email, Encryption.decrypt_password(password))
		old_controller = @controller
		@controller = MaterialsController.new
		post :create, :format => :json, :material => {"material_type" => 1, "location" => "location_1", "title" => "title_1"}
		material_id_1 = JSON.parse(@response.body)["_id"]
		post :create, :format => :json, :material => {"material_type" => 1, "location" => "location_2", "title" => "title_2"}
		material_id_2 = JSON.parse(@response.body)["_id"]
		post :create, :format => :json, :material => {"material_type" => 1, "location" => "location_3", "title" => "title_3"}
		material_id_3 = JSON.parse(@response.body)["_id"]
		post :create, :format => :json, :material => {"material_type" => 2, "location" => "location_4", "title" => "title_4"}
		material_id_4 = JSON.parse(@response.body)["_id"]
		post :create, :format => :json, :material => {"material_type" => 2, "location" => "location_5", "title" => "title_5"}
		material_id_5 = JSON.parse(@response.body)["_id"]
		post :create, :format => :json, :material => {"material_type" => 4, "location" => "location_6", "title" => "title_6"}
		material_id_6 = JSON.parse(@response.body)["_id"]
		@controller = old_controller
		sign_out
		return [material_id_1, material_id_2, material_id_3, material_id_4, material_id_5, material_id_6]
	end
end

