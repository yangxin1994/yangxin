require 'result_job'
module Jobs

	class DataListJob < ResultJob
		
		def perform
			# set the type of the job
			set_status({"result_type" => "data_list"})

			# get parameters
			filter_index = options["filter_index"].to_i
			include_screened_answer = options["include_screened_answer"].to_s == "true"
			survey_id = options["survey_id"]

			# get answers set by filter
			answers = get_answers(survey_id, filter_index, include_screened_answer)

			# generate result key
			result_key = DataListJob.generate_result_key(answers)

			# judge whether the result_key already exists
			result = DataListResult.find_by_result_key(result_key)

			#create new result record
			if !result.nil?
				data_list_result = DataListResult.create(:result_key => result_key, :job_id => status["uuid"], :ref_result_id => result._id)
				set_status({"ref_job_id" => result.job_id})
				return
			else
				data_list_result = DataListResult.create(:result_key => result_key, :job_id => status["uuid"])
			end
			# analy answers info
			answer_info = self.analyze_answer_info(answers)

			# update answer info and set the job finished
			data_list_result.answer_info = answer_info
			data_list_result.status = 1
			data_list_result.save
		end

		def self.generate_result_key(answers)
			answer_ids = answers.map { |e| e._id.to_s }
			result_key = Digest::MD5.hexdigest("data_list-#{answer_ids.to_s}")
			return result_key
		end

		def analyze_answer_info(answers)
			answer_info = []
			answers_length = answers.length
			answers.each_with_index do |a, index|
				info = {}
				info["email"] = a.user.nil? ? "" : a.user.email.to_s
				info["true_name"] = a.user.nil? ? "" : a.user.true_email.to_s
				info["answer_time"] = a.created_at.to_i
				info["duration"] = a.finished_at - a.created_at.to_i
				info["region"] = a.region
				answer_info << info
				set_status({"answer_info_progress" => (index + 1) * 1.0 / answers_length })
			end
			return answer_info
		end
	end
end
