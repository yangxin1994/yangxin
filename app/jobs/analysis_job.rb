require 'result_job'
module Jobs

	class AnalysisResult < ResultJob

		@queue = :result_job

		def perform
			# set the type of the job
			set_status({"result_type" => "analysis_result"})

			# get parameters
			filter_index = options["filter_index"].to_i
			include_screened_answer = options["include_screened_answer"].to_s == "true"
			survey_id = options["survey_id"]

			# get answers set by filter
			answers = ResultJob.answers(survey_id, filter_index, include_screened_answer)

			# generate result key
			result_key = sef.generate_result_key(answers)

			# judge whether the result_key already exists
			result = AnalysisResult.find_by_result_key(result_key)
			#create new result record
			if !result.nil?
				analysis_result = AnalysisResult.create(:result_key => result_key, :job_id => status["uuid"], :ref_result_id => result._id)
				set_status({"ref_job_id" => result.job_id})
				return
			else
				analysis_result = AnalysisResult.create(:result_key => result_key, :job_id => status["uuid"])
			end

			# analy answers info
			answer_info = self.analyze_answer_info(answers)

			# update answer info and set the job finished
			analysis_result.answer_info = answer_info
			analysis_result.save
			set_status({"is_finished" => true})
		end

		def generate_result_key(answers)
			answer_ids = answers.map { |e| e._id.to_s }
			result_key = Digest::MD5.hexdigest("analyze_result-#{answer_ids.to_s}")
			return result_key
		end

    def analysis(answers)
      address_result = Address.province_hash.merge(Address.city_hash)
      channel_result = {}
      duration_mean = []
      
      answers.each do |answer|
        # analyze region
        region = answer.region
        address_result[region] = address_result[region] + 1 if !address_result[region].nil?

        # analyze channel
        channel = answer.channel
        channel_result[channel] = 0 if channel_result[channel].nil?
        channel_result[channel] = channel_result[channel] + 1

        # analyze duration
        duration_mean << answer.finished_at - answer.created_at.to_i
      end

      duration_mean = duration_mean.mean
    end

		def analyze_answer_info(answers)
			answer_info = []
			answers_length = answers.length
			answers.each_with_index do |a, index|
				info = {}
				info["email"] = a.user.email
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
