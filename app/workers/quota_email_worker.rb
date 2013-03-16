class QuotaEmailWorker
	include Sidekiq::Worker
	sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform
		# 1. get all samples, excluding those are in the blacklist
		user_ids = User.ids_not_in_blacklist
		# 2. get the surveys that need to send emails
		published_survey = Survey.get_published_active_surveys
		# 3. find out samples for surveys
		surveys_for_user = {}
		surveys_for_imported_email = {}
		published_survey.each do |survey|
			s_id = survey._id.to_s
			email_number = survey.promote_email_number
			next if email_number == 0
			user_ids_answered = survey.get_user_ids_answered
			user_ids_sent = EmailHistory.get_user_ids_sent(s_id)
			user_ids = user_ids - user_ids_answered - user_ids_sent
			samples_found = user_ids.length > email_number ? user_ids.shuffle[0..email_number-1] : user_ids
			user_email_history_batch = []
			samples_found.each do |u_id|
				surveys_for_user[u_id] ||= []
				surveys_for_user[u_id] << survey._id.to_s
				user = User.find_by_id(u_id)
				user_email_history_batch << { :user_id => user._id, :survey_id => survey._id } if !user.nil?
			end
			# update email history for users
			EmailHistory.collection.insert(user_email_history_batch)
			if samples_found.length < email_number
				imported_email_history_batch = []
				emails_sent = EmailHistory.get_emails_sent(s_id)
				ImportEmail.random_emails(email_number - samples_found.length, emails_sent).each do |email|
					surveys_for_imported_email[email] ||= []
					surveys_for_imported_email[email] << survey._id.to_s
					imported_email_history_batch << { :email => email, :survey_id => survey._id }
				end
				# update email history for import users
				EmailHistory.collection.insert(imported_email_history_batch)
			end
		end
		# 4. send emails to the samples found
		# since this may consume long time, we do this in a separate thread
		surveys_for_user.each do |u_id, s_id_ary|
			UserMailer.survey_email(u_id, s_id_ary).deliver
		end
		surveys_for_imported_email.each do |email, s_id_ary|
			begin
				UserMailer.imported_email_survey_email(email, s_id_ary).deliver
			rescue
			end
		end
		return true
	end
end
