class TempEmailWorker
	include Sidekiq::Worker
	sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform(index, digit)
		s_id_ary = ["5142b0de408c9950a9000030", "514661c9408c99fcd700001e"]
		import_emails = ImportEmail.all.to_a
		while true
			import_email = import_emails[digit]
			digit += 10
			return if import_email.nil?
			next if import_email.sent
			import_email.sent = true
			import_email.save
			begin
				Object.const_get("Temp#{index}Mailer").imported_email_survey_email(import_email.email, s_id_ary).deliver
			rescue
				import_email.sent = false
				import_email.save
			end
		end
	end
end
