require 'result_job'
module Jobs

	class ReportJob < ResultJob

		@queue = :result_job

		def perform
			# set the type of the job
			set_status({"result_type" => "report"})

			# get parameters
			filter_index = options["filter_index"].to_i
			include_screened_answer = options["include_screened_answer"].to_s == "true"
			report_mockup_id = options["report_mockup_id"].to_s
			report_style = options["report_style"].to_i
			report_type = options["report_type"].to_s

			# get answers set by filter
			answers = ResultJob.answers(survey_id, filter_index, include_screened_answer)

			# generate result key
			result_key = sef.generate_result_key(answers, report_mockup, report_style, report_type)

			# judge whether the result_key already exists
			result = DataListResult.find_by_result_key(result_key)
			#create new result record
			if !result.nil?
				report_result = DataListResult.create(:result_key => result_key, :job_id => status["uuid"], :ref_result_id => result._id)
				set_status({"ref_job_id" => result.job_id})
				return
			else
				report_result = DataListResult.create(:result_key => result_key, :job_id => status["uuid"])
			end

			# analyze the result


			# update file location
			report_result.answer_info = file_location
			report_result.save
			set_status({"is_finished" => true})
		end

		def generate_result_key(answers, report_mockup, report_style, report_type)
			answer_ids = answers.map { |e| e._id.to_s }
			result_key = Digest::MD5.hexdigest("report-#{report_mockup.to_json}-#{report_style}-#{report_type}-#{answer_ids.to_s}")
			return result_key
		end
	end
end
