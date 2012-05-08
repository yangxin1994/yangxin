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

end
