FactoryGirl.define do
	factory :survey_auditor, class: SurveyAuditor do
		email "survey_auditor@test.com"
		password Encryption.encrypt_password("123456")
		username "survey_auditor"
		status 4
		activate_time Time.now.to_i
		true_name "survey auditor"
		lock "survey auditor"
		system_user_type 2
	end
end
