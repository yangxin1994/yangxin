module Jobs

	class SurveyDeadlineJob

		@queue = :sd_job_queue

		def self.perform(*args)
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			survey_id = arg["survey_id"]

			unless survey_id
				puts "Must provide survey_id"
				return false
			end
			puts "do survey job in #{Time.now}"

			#do
      action(survey_id)
		end

		def self.action(survey_id)
			survey = Survey.find(survey_id)
			unless survey
				puts "survey can not find by id: #{survey_id}"
				return false
			end
			survey.publish_status = 1
			survey.save
		end

		def self.update(survey_id, deadline)
			Resque.remove_delayed(SurveyDeadlineJob, "survey_id" => survey_id)
			Resque.enqueue_at(deadline, 
				SurveyDeadlineJob, 
				{"survey_id"=> survey_id})
		end
	end
end
