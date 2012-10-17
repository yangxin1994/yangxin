module Jobs

	class EmailSendingJob

		@@recurring = false
		@queue = :es_job_queue


		def self.perform(*args)
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			email_type = arg["email_type"]

			if email_type.blank?
				Rails.logger.error "SurveyDeadlineJob: Must provide email_type"
				return false
			end


			case email_type
			when "welcome"
				user = User.find_by_email(arg["user_email"])
				UserMailer.welcome_email(user).deliver
			when "activate"
				user = User.find_by_email(arg["user_email"])
				UserMailer.activate_email(user).deliver
			when "password"
				user = User.find_by_email(arg["user_email"])
				UserMailer.password_email(user).deliver
			when "normal"
				arg["receiver_list"].split(';').each do |email|
					Resque.enqueue_at_with_queue(1, Time.now, OopsMailJob,{
						:mailler => "netranking",
						:account_name => account[:netranking]["account_name"],
						:account_secret => account[:netranking]["account_secret"],
						:mail_list => email,
						:subject => arg["title"],
						:content => arg["content"]
					})
				end
			end
		end
	end
end
