class TempEmailWorker
	include Sidekiq::Worker
	sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform(index)
		s_id_ary = ["5142b0de408c9950a9000030", "514661c9408c99fcd700001e"]
		while true
			import_email = ImportEmail.not_sent.shuffle[0]
			import_email.sent = true
			import_email.save
			begin
				Object.get_const("Temp#{index}Mailer").imported_email_survey_email(import_email.email, s_id_ary).deliver
			rescue
				import_email.sent = false
				import_email.save
			end
		end
	end
end
