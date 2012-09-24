module Jobs

	class EmailSendingJob

		@@recurring = false
		@queue = :es_job_queue


		def self.perform(*args)
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			email_type = arg["email_type"]
			user_email = arg["user_email"]

			if email_type.blank?
				Rails.logger.error "SurveyDeadlineJob: Must provide email_type"
				return false
			end

			user = User.find_by_email(user_email)

			case email_type
			when "welcome"
				UserMailer.welcome_email(user).deliver
			when "activate"
				UserMailer.activate_email(user).deliver
			when "password"
				UserMailer.password_email(user).deliver
			end
		end
	end
end
