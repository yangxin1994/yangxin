class EmailWorker
	include Sidekiq::Worker
	sidekiq_options :retry => false

	def perform(email_type, email, callback, opt={})
		puts "00000000000000000000"
		puts email_type
		puts "00000000000000000000"
		puts email
		user = User.find_by_email(email)
		return false if user.nil?
		case email_type
		when 'welcome'
			UserMailer.welcome_email(user, callback).deliver
		when 'activate'
			UserMailer.activate_email(user, callback).deliver
		when 'password'
			UserMailer.password_email(user, callback).deliver
		when 'lottery_code'
			puts "111111111111111111"
			puts opt["survey_id"]
			puts "222222222222222222"
			puts opt["lottery_code_id"]
			puts "333333333333333333"
			puts callback
			UserMailer.lottery_code_email(user, opt["survey_id"], opt["lottery_code_id"], callback).deliver
		end
		return true
	end
end
