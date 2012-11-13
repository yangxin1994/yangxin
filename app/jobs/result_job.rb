#encoding: utf-8

module Jobs

	class ResultJob
		include Resque::Plugins::Status
		include ConnectDotNet
		@queue = :result_job

		def self.answers(survey_id, filter_index, include_screened_answer)
			survey = Survey.find_by_id(survey_id)
			# answers = include_screened_answer ? survey.answers.not_preview.finished_and_screened : survey.answers.not_preview.finished
			answers = include_screened_answer ? survey.answers.finished_and_screened : survey.answers.finished
			if filter_index == -1
				# set_status({"find_answers_progress" => 1})
				return answers
			end
			filter_conditions = self.survey.filters[filter_index]["conditions"]
			filtered_answers = []
			answers_length = answers.length
			answers.each_with_index do |a, index|
				filtered_answers << a if a.satisfy_conditions(filter_conditions)
				# set_status({"find_answers_progress" => (index + 1) * 1.0 / answers_length})
			end
			return filtered_answers	
		end

    def filtered_answers
      #@survey.answers.not_preview.finished_and_screened
      DataListResult.find_by_result_key(@data_list_result.result_key).answer_info
    end

    def answer_contents
      a = filtered_answers
      @retval = []
      q = @survey.all_questions_type
      p "========= 准备完毕 ========="
      @result.answers_count = a.size
      a.each_with_index do |answer, index|
        line_answer = []
        i = -1
        #begin
          #TODO 异常处理
          answer.answer_content.each do |k, v|
            line_answer += q[i += 1].answer_content(v)
          end
        #end
        set_status({"export_answers_progress" => (index + 1) * 1.0 / @result.answers_count })
        
        p "========= 转出 #{index} 条 进度 #{set_status["export_answers_progress"]} =========" if index%10 == 0
        @retval << line_answer
      end
      @result.answer_contents = @retval
      @result.save
      @retval
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
					histogram[segment_index] = histogram[segment_index] + 1
				end
				result["histogram"] = histogram
			end
			return result
		end

		def analyze_time_blank(issue, answer_ary, segment=[])
			result = {}
			# the raw answers are in the unit of milliseconds
			answer_ary.map! { |e| (e / 1000).round }
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
			answer_ary.each do |value|
				region_code = value["address"]
				result[region_code] = 0 if result[region_code].nil?
				result[region_code] = result[region_code] + 1
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

		def analyze_scale(issue, answer_ary)
			input_ids = issue["items"].map { |e| e["id"] }
			scores = {}
			input_ids.each { |input_id| scores[input_id] = [] }
			
			answer_ary.each do |answer|
				answer.each do |input_id, value|
					# value is 0-based, should be converted to score-based
					scores[input_id] << value + 1 if !scores[input_id].nil? && value.to_i != -1
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
