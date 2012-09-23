module Jobs

	class SurveyDeadlineJob

		@@recurring = false
		@queue = :sd_job_queue


		def self.perform(*args)
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			survey_id = arg["survey_id"]

			unless survey_id
				Rails.logger.error "SurveyDeadlineJob: Must provide survey_id"
				return false
			end
			puts "do survey job in #{Time.now}"

			#do
			action(survey_id)
		end

		def self.action(survey_id)
			survey = Survey.find(survey_id)
			unless survey
				Rails.logger.error "SurveyDeadlineJob: Survey can not find by id: #{survey_id}"
				return false
			end
			# the publish status of the survey is set as closed
			survey.publish_status = 1
			# the result of the survey should be analyzed
			survey.refresh_results
			survey.save
		end
	end
end
