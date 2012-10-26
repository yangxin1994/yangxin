require 'result_job'
module Jobs

	class AnalysisJob < ResultJob

		@queue = :result_job

		def perform
			# set the type of the job
			set_status({"result_type" => "analysis"})

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

			# analyze result
			region_result, channel_result, duration_mean, time_result, answer_result = *self.analysis(answers)

			# update analysis result
			analysis_result.region_result = region_result
			analysis_result.channel_result = channel_result
			analysis_result.duration_mean = duration_mean
			analysis_result.time_result = time_result
			analysis_result.answer_result = answer_result
			analysis_result.status = 1
			analysis_result.save
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
			answers_transform = {}
			
			answers.each_with_index do |answer, index|
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
				answer.answer_content.each do |q_id, question_answer|
					answers_transform[q_id] << question_answer if !question_answer.blank?
				end

				set_status({"analyze_answer_progress" => 0.5 * (index + 1) * 1.0 / answers.length })
			end
			
			# calculate the mean of duration
			duration_mean = duration_mean.mean

			# make stats of the finish time
			min_finish_time = finish_time.min
			min_finish_date = Time.at(min_finish_time).to_date
			start_day = [min_finish_date.year, min_finish_date.month, min_finish_date.day]
			day_number = (finish_time.max / 86400 - min_finish_time / 86400) + 1
			time_histogram = Array.new(day_number, 0)
			finish_time.each do |t|
				time_histogram[t / 86400 - min_finish_time / 86400] = time_histogram[t / 86400 - min_finish_time / 86400] + 1
			end
			time_result = {"start_day" => start_day, "time_histogram" => time_histogram}
			set_status({"analyze_answer_progress" => 0.6 })

			# make stats for the answers
			answer_result = {}
			answers_transform.each do |q_id, question_answer_ary|
				question = Question.find_by_id(q_id)
				answer_result[q_id] = [question, question_answer_ary.length, analyze_one_question_answers(question, question_answer_ary)]
				set_status({"analyze_answer_progress" => 0.6 + 0.4 * aindex / answers_transform.length })
			end

			return [region_result, channel_result, duration_mean, time_result, answer_result]
		end

		def analyze_one_question_answers(question, answer_ary)
			case question.question_type
			when QuestionTypeEnum::CHOICE_QUESTION
				return analyze_choice(question.issue, answer_ary)
			when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
				return analyze_matrix_choice(question.issue, answer_ary)
			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				return analyze_number_blank(question.issue, answer_ary)
			when QuestionTypeEnum::TIME_BLANK_QUESTION
				return analyze_time_blank(question.issue, answer_ary)
			when QuestionTypeEnum::EMAIL_BLANK_QUESTION
				return analyze_email_blank(question.issue, answer_ary)
			when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
				return analyze_address_blank(question.issue, answer_ary)
			when QuestionTypeEnum::BLANK_QUESTION
				return analyze_blank(question.issue, answer_ary)
			when QuestionTypeEnum::MATRIX_BLANK_QUESTION
				return analyze_matrix_blank(question.issue, answer_ary)
			when QuestionTypeEnum::TABLE_QUESTION
				return analyze_table(question.issue, answer_ary)
			when QuestionTypeEnum::CONST_SUM_QUESTION
				return analyze_const_sum(question.issue, answer_ary)
			when QuestionTypeEnum::SORT_QUESTION
				return analyze_sort(question.issue, answer_ary)
			when QuestionTypeEnum::RANK_QUESTION
				return analyze_rank(question.issue, answer_ary)
			end
		end

		def analyze_choice(issue, answer_ary)
			input_ids = issue["items"].map { |e| e["id"] }
			input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
			result = {}
			input_ids.each { |input_id| result[input_id] = 0 }
			answer_ary.each do |answer|
				answer["selection"].each do |input_id|
					result[input_id] = result[input_id] + 1 if !result[input_id].nil?
				end
			end
			return result
		end

		def analyze_matrix_choice(issue, answer_ary)
			input_ids = issue["choices"].map { |e| e["id"] }
			result = []
			issue["rows"].each do |row|
				input_ids.each do |input_id|
					result["#{row["id"]}-#{input_id}"] = 0
				end
			end
	
			answer_ary.each do |answer|
				answer.each_with_index do |row_answer, row_index|
					row_id = issue["rows"][row_index]["id"]
					row_answer.each do |input_id|
						result["#{row_id}-#{input_id}"] = result["#{row_id}-#{input_id}"] + 1 if !result["#{row_id}-#{input_id}"].nil?
					end
				end
			end
			return result
		end

		def analyze_number_blank(issue, answer_ary, segment=[])
			result = {}		
			answer_ary.map! { |answer| answer.to_f }
			answer_ary.sort!
			result["mean"] = answer_ary.mean
			if !segment.blank?
				histogram = Array(segment.length + 1, 0)
				segment_index = 0
				answer_ary.each do |a|
					while a > segment[segment_index]
						segment_index = segment_index + 1
						break if segment_index >= segment.length
					end
					histogram = histogram + 1
				end
				result["histogram"] = histogram
			end
			return result
		end

		def analyze_time_blank(issue, answer_ary, segment=[])
			result = {}
			# convert the time format from array to integer
			answer_ary = answer_ary.map! do |answer|
				Time.mktime(*(answer.map {|e| e.to_i })).to_i
			end
			answer_ary.sort!
			result["mean"] = answer_ary.mean
			if !segment.blank?
				histogram = Array(segment.length + 1, 0)
				segment_index = 0
				answer_ary.each do |a|
					while a > segment[segment_index]
						segment_index = segment_index + 1
						break if segment_index >= segment.length
					end
					histogram = histogram + 1
				end
				result["histogram"] = histogram
			end
			return result
		end

		def analyze_email_blank(issue, answer_ary)
			result = {}
			answer_ary.each do |email_address|
				domain_name = (email_address.split('@'))[-1]
				result[domain_name] = 0 if result[domain_name].nil?
				result[domain_name] = result[domain_name] + 1
			end
			return result
		end

		def analyze_address_blank(issue, answer_ary)
			result = {}
			if issue["format"].to_i & 2
				# county is required
				result = Address.county_hash
				answer_ary = answer_ary.map! do |answer|
					answer[2].to_i
				end
			elsif issue["format"].to_i & 4
				# city is required
				result = Address.province_hash
				answer_ary = answer_ary.map! do |answer|
					answer[1].to_i
				end
			else
				# only province is required
				result = Address.city_hash
				answer_ary = answer_ary.map! do |answer|
					answer[0].to_i
				end
			end
			answer_ary.each do |value|
				result[value] = result[value] + 1 if !result[value].nil?
			end
			return result
		end

		def analyze_blank(issue, answer_ary)
			result = {}
			issue["items"].each_with_index do |input, input_index|
				case input["data_type"]
				when "Number"
					result[input["id"]] = analyze_number_blank(input["properties"], answer_ary.map { |e| e[input_index] })
				when "Address"
					result[input["id"]] = analyze_address_blank(input["properties"], answer_ary.map { |e| e[input_index] })
				when "Email"
					result[input["id"]] = analyze_email_blank(input["properties"], answer_ary.map { |e| e[input_index] })
				when "Time"
					result[input["id"]] = analyze_time_blank(input["properties"], answer_ary.map { |e| e[input_index] })
				end
			end
			return result
		end

		def analyze_const_sum(issue, answer_ary)
			input_ids = issue["items"].map { |e| e["id"] }
			input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
			weights = {}
			input_ids.each { |input_id| weights[input_id] = [] }

			answer_ary.each do |answer|
				answer.each do |input_id, value|
					weights[input_id] << value.to_f if !weights[input_id].nil?
				end
			end

			result = {}
			weights.each do |key, weight_ary|
				result[key] = weight_ary.mean
			end

			return result
		end

		def analyze_sort(issue, answer_ary)
			input_ids = issue["items"].map { |e| e["id"] }
			input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
			
			input_number = input_ids.length
			result = {}
			input_ids.each do |input_id|
				result[input_id] = Array(input_number, 0)
			end
	
			answer_ary.each do |answer|
				answer["sort_result"].each_with_index do |input_id, sort_index|
					result[input_id][sort_index] = result[input_id][sort_index] + 1 if sort_index < input_number
				end
			end
	
			return result
		end

		def analyze_rank(issue, answer_ary)
			input_ids = issue["items"].map { |e| e["id"] }
			input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
			scores = {}
			input_ids.each { |input_id| scores[input_id] = [] }
			
			answer_ary.each do |answer|
				answer.each do |input_id, value|
					scores[input_id] << value if !scores[input_id].nil? && value.to_i != -1
				end
			end
	
			result = {}
			scores.each do |key, score_ary|
				result[key] = []
				result[key] << score_ary.length
				result[key] << (score_ary.blank? ? -1 : score_ary.mean)
			end
	
			return result
		end
	end
end
