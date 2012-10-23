require 'result_job'
module Jobs

	class AnalysisJob < ResultJob

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
			[region_result, channel_result, duration_mean] = self.analysis(answers)

			# update analysis result
			analysis_result.region_result = region_result
			analysis_result.channel_result = channel_result
			analysis_result.duration_mean = duration_mean
			analysis_result.save
			set_status({"is_finished" => true})
		end

		def generate_result_key(answers)
			answer_ids = answers.map { |e| e._id.to_s }
			result_key = Digest::MD5.hexdigest("analyze_result-#{answer_ids.to_s}")
			return result_key
		end

		def analysis(answers)
			region_result = Address.province_hash.merge(Address.city_hash)
			channel_result = {}
			duration_mean = []
			finish_time = []
			
			answers.each do |answer|
				# analyze region
				region = answer.region
				region_result[region] = region_result[region] + 1 if !region_result[region].nil?
				
				# analyze channel
				channel = answer.channel
				channel_result[channel] = 0 if channel_result[channel].nil?
				channel_result[channel] = channel_result[channel] + 1
				
				# analyze duration
				duration_mean << answer.finished_at - answer.created_at.to_i

				# analyze time
				finish_time << answer.finished_at

				# re-organize answers
				all_answer_content = answer.answer_content.mrege(answer.template_answer_content)
				all_answer_content.each do |q_id, question_answer|
					answers_transform[q_id] << question_answer if !question_answer.blank?
				end
			end
			
			# calculate the mean of duration
			duration_mean = duration_mean.mean

			# make stats of the finish time

			return [region_result, channel_result, duration_mean]
		end

	end
end
