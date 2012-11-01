# encoding: utf-8
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
			report_mockup = ReportMockup.find_by_id(report_mockup_id)
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

			# transform the answers
			answers.each_with_index do |answer, index|
				# re-organize answers
				answer.answer_content.each do |q_id, question_answer|
					answers_transform[q_id] << question_answer if !question_answer.blank?
				end
			end

			analysis_results = []
			# analyze the result based on the report mockup
			report_mockup.components.each do |component|
				if component["component_type"] == 0
					# this is a single question analysis
					question_id = component["value"]["id"]
					question = BasicQuestion.find_by_id(question_id)
					case question.question_type
					when QuestionTypeEnum::CHOICE_QUESTION
						analysis_result = analyze_choice(question.issue, answers_transform[question_id])
						# judge whether this is a single choice or multiple choice
						if question.issue["max_choice"] == 1
							text = single_choice_description(analysis_result, question.issue)
							analysis_results << {"question_type" => "single_choice",
												"result" => analysis_result,
												"text" => text}
						else
							pie_text = multiple_choice_description(analysis_result, question.issue, answers.length, 'pie')
							bar_text = multiple_choice_description(analysis_result, question.issue, answers.length, 'bar')
							analysis_results << {"question_type" => "single_choice",
												"result" => analysis_result,
												"pie_text" => pie_text,
												"bar_text" => bar_text}
						end
					when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
						analysis_result = analyze_matrix_choice(question.issue, answers_transform[question_id])
						text = matrix_choice_description(analysis_result, question.issue)
					when QuestionTypeEnum::NUMBER_BLANK_QUESTION
						analysis_result = analyze_number_blank(question.issue, answers_transform[question_id], component["value"]["format"] || [])
						text = number_blank_description(analysis_result, question.issue, component["value"]["format"] || [])
					when QuestionTypeEnum::TIME_BLANK_QUESTION
						analysis_result = analyze_time_blank(question.issue, answers_transform[question_id])
						text = time_blank_description(analysis_result, question.issue, component["value"]["format"] || [])
					when QuestionTypeEnum::EMAIL_BLANK_QUESTION
						analysis_result = analyze_email_blank(question.issue, answers_transform[question_id])
					when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
						analysis_result = analyze_address_blank(question.issue, answers_transform[question_id])
						text = address_blank_description(analysis_result, question.issue)
					when QuestionTypeEnum::BLANK_QUESTION
						analysis_result = analyze_blank(question.issue, answers_transform[question_id])
					when QuestionTypeEnum::MATRIX_BLANK_QUESTION
						analysis_result = analyze_matrix_blank(question.issue, answers_transform[question_id])
					when QuestionTypeEnum::TABLE_QUESTION
						analysis_result = analyze_table(question.issue, answers_transform[question_id])
					when QuestionTypeEnum::CONST_SUM_QUESTION
						analysis_result = analyze_const_sum(question.issue, answers_transform[question_id])
						text = const_sum_description(analysis_result, question.issue)
					when QuestionTypeEnum::SORT_QUESTION
						analysis_result = analyze_sort(question.issue, answers_transform[question_id])
						text = sort_description(analysis_result, question.issue, answers.length)
					when QuestionTypeEnum::RANK_QUESTION
						analysis_result = analyze_rank(question.issue, answers_transform[question_id])
					when QuestionTypeEnum::SCALE_QUESTION
						analysis_result = analyze_scale(question.issue, answers_transform[question_id])
						text = scale_description(analysis_result, question.issue, answers.length)
					end
				else
					# this is a cross questions analysis
				end
			end

		end

		def generate_result_key(answers, report_mockup, report_style, report_type)
			answer_ids = answers.map { |e| e._id.to_s }
			result_key = Digest::MD5.hexdigest("report-#{report_mockup.to_json}-#{report_style}-#{report_type}-#{answer_ids.to_s}")
			return result_key
		end

		def get_item_text_by_id(items, id)
			item = items.select { |e| e["id"] == input_id }
			return nil if item.nil?
			item_text = item[0]["content"]["text"]
		end

		def scale_description(analysis_result, issue)
			results = []
			analysis_result.each do |input_id, ele|
				if ele[1] != -1
					item_text = get_item_text_by_id(input_id)
					results << { "text" => , "score" => ele[1] } 
				end
			end
			return "" if results.blank?
			results.sort_by! { |e| -e["ratio"] }
			item_text_ary = results.map { |e| e["text"] }
			score_ary = results.map { |e| e["score"] }

			text = "调查显示，#{item_text_ary[0]}的平均得分最高，为#{score_ary[0]}"
			# one item
			return text + "。" if item_text_ary.length == 1
			text = text + "，其次是#{item_text_ary[1]}，平均得分是#{score_ary[1]}"
			# two items
			return text + "。" if item_text_ary.length == 2
			# three items
			return text + "，#{item_text_ary[2]}的平均得分为#{score_ary[2]}。"
			# more than three items
			item_text_string = item_text_ary[2..-1].join('、')
			score_string = score_ary[2..-1].join('、')
			return text + "，#{item_text_string}的平均得分分别为#{score_string}。"
		end

		def sort_description(analysis_result, issue, answer_number)
			return "" if analysis_result.blank?
			first_index_dist = {}
			second_index_dist = {}
			analysis_result.each do |input_id, sort_number_ary|
				first_index_dist[input_id] = (sort_number_ary[0] * 100.0 / answer_number).round
				second_index_dist[input_id] = (sort_number_ary[1] * 100.0 / answer_number).round if sort_number_ary.length > 1
			end
			# handle the result for the first index
			first_index_results = []
			first_index_dist.each do |input_id, ratio|
				item_text = get_item_text_by_id(issue["items"], input_id)
				next if item_text.nil?
				first_index_results << { "text" => item_text, "ratio" => ratio }
			end
			first_index_results.sort_by! { |e| -e["ratio"] }
			first_index_item_text_ary = results.map { |e| e["text"] }
			first_index_ratio_ary = results.map { |e| e["ratio"] }
			text = "调查显示，将#{first_index_results_text_ary[0]}排在第一位的被访者所占比例最高，为#{first_index_ratio_ary[0]}%"
			if first_index_results_text_ary.length == 1
			elsif first_index_results_text_ary.lenght == 2
				text = text + "，其次是#{first_index_results_text_ary[1]}，所占比例为#{first_index_ratio_ary[1]}%"
			else
				text = text + "，其次是#{first_index_results_text_ary[1]}和#{first_index_results_text_ary[2]}，所占比例为#{first_index_ratio_ary[1]}%和#{first_index_ratio_ary[2]}%"
			end
			# handle the result for the second index
			second_index_results = []
			second_index_dist.each do |input_id, ratio|
				item_text = get_item_text_by_id(issue["items"], input_id)
				next if item_text.nil?
				second_index_results << { "text" => item_text, "ratio" => ratio }
			end
			second_index_results.sort_by! { |e| -e["ratio"] }
			second_index_item_text_ary = results.map { |e| e["text"] }
			second_index_ratio_ary = results.map { |e| e["ratio"] }
			return text + "。" if second_index_results_text_ary.length == 1
			text = text + "；在第二位的排序中，#{second_index_results_text_ary[0]}所占比例最高，为#{second_index_ratio_ary[0]}%"
			if second_index_results_text_ary.length == 2
				return text + "，其次是#{second_index_results_text_ary[1]}，所占比例为#{second_index_ratio_ary[1]}%。"
			else
				return text + "，其次是#{second_index_results_text_ary[1]}和#{second_index_results_text_ary[2]}，所占比例为#{second_index_ratio_ary[1]}%和#{second_index_ratio_ary[2]}%。"
			end
		end

		def const_sum_description(analysis_result, issue)
			return "" if analysis_result.blank?
			analysis_result.each do |input_id, mean_weight|
				item_text = get_item_text_by_id(issue["items"], input_id)
				next if item_text.nil?
				results << { "text" => item_text, "mean_weight" => mean_weight.to_f }
			end
			results.sort_by! { |e| -e["mean_weight"] }
			item_text_ary = results.map { |e| e["text"] }
			mean_weight_ary = results.map { |e| e["mean_weight"] }
			
			text = "调查显示，被访者为#{item_text_ary[0]}分配的比重最高，平均为#{mean_weight_ary[0]}"
			# one item
			return text + "。" if results.length == 1
			text = text + "，其次是#{item_text_ary[1]}，所占比重为#{mean_weight_ary[1]}"
			# two items
			return text + "。" if results.length == 2
			# three items
			return text + "，#{item_text_ary[2]}所占比重为#{mean_weight_ary[2]}。" if results.length == 3
			# at least four items
			item_text_string = item_text_ary[2..-1].join('、')
			mean_weight_string = mean_weight_ary[2..-1].join('、')
			return text + "，#{item_text_string}所占比重分别为#{mean_weight_string}。"
		end

		def address_blank_description(analysis_result, issue)
			total_number = 0
			return "" if analysis_result.blank?
			analysis_result.each do |region_code, number|
				address_text = Address.find_text_by_code(region_code)
				next if address_text.nil?
				total_number = total_number + number
				results << { "text" => address_text, "number" => number.to_f }
			end
			results.sort_by! { |e| -e["number"] }
			address_text_ary = results.map { |e| e["text"] }
			ratio_ary = results.map { |e| (e["number"] * 100 / total_number).round }

			text = "调查显示，被访者中，#{ratio_ary[0]}%的人填写#{address_text_ary[0]}，所占比例最高"
			# only one address
			return text + "。" if results.length == 1
			text = text + "，其次是%#{address_text_ary[1]}，填写比例是#{ratio_ary[1]}"
			# two addresses
			return text + "。" if results.length == 2
			# three addresses
			return text + "，填写#{address_text_ary[2]}的比例为#{ratio_ary[2]}%。" if results.length == 3
			# four addresses
			return text + "，填写#{address_text_ary[2]}、#{address_text_ary[3]}的比例分别为#{ratio_ary[2]}%、#{ratio_ary[3]}%。" if results.length == 4
			# at least five addresses
			text = text + "，填写#{address_text_ary[2]}、#{address_text_ary[3]}、#{address_text_ary[4]}的比例分别为#{ratio_ary[2]}%、#{ratio_ary[3]}%、#{ratio_ary[4]}%"
			return text + "。" if results.length == 5
			# six addresses
			return text + "，另有#{ratio_ary[5]}%的人填写了#{address_text_ary[5]}。" if results.length == 6
			# more than six addresses
			other_ratio = 100 - ratio_array[1..4].sum
			return text + "，另有#{other_ratio}%的人填写了其他。"
		end

		def convert_time_interval_to_text(format, v1, v2)
			case format.to_i
			when 0
				# year
				if v1.nil?
					y = Time.at(v2).year
					return "#{y}年以前"
				elsif v2.nil?
					y = Time.at(v1).year + 1
					return "#{y}年以后"
				else
					y1 = Time.at(v1).year + 1
					y2 = Time.at(v2).year
					return y1 == y2 ? "#{y1}年" : "#{y1}年到#{y2}年"
				end
			when 1
				# year, month
				if v1.nil?
					y = Time.at(v2).year
					m = Time.at(v2).month
					return "#{y}年#{m}月以前"
				elsif v2.nil?
					y = Time.at(v1).year
					m = Time.at(v1).month + 1
					return "#{y}年#{m}月以后"
				else
					y1 = Time.at(v1).year
					m1 = Time.at(v1).month + 1
					y2 = Time.at(v2).year
					m2 = Time.at(v2).month
					return y1 == y2 && m1 == m2 ? "#{y1}年#{m1}月" : "#{y1}年#{m1}月到#{y2}年#{m2}月"
				end
			when 2
				# year, month, day
				if v1.nil?
					y = Time.at(v2).year
					m = Time.at(v2).month
					d = Time.at(v2).day
					return "#{y}年#{m}月#{d}日以前"
				elsif v2.nil?
					y = Time.at(v1).year
					m = Time.at(v1).month
					d = Time.at(v1).day + 1
					return "#{y}年#{m}月#{d}日以后"
				else
					y1 = Time.at(v1).year
					m1 = Time.at(v1).month
					d1 = Time.at(v1).day + 1
					y2 = Time.at(v2).year
					m2 = Time.at(v2).month
					d2 = Time.at(v2).day
					return y1 == y2 && m1 == m2 && d1 == d2 ? "#{y1}年#{m1}月#{d1}日" : "#{y1}年#{m1}月#{d1}日到#{y2}年#{m2}月#{d2}日"
				end
			when 3
				# year, month, day, hour, minute
				if v1.nil?
					y = Time.at(v2).year
					m = Time.at(v2).month
					d = Time.at(v2).day
					h = Time.at(v2).hour
					min = Time.at(v2).minute
					return "#{y}年#{m}月#{d}日#{h}时#{min}分以前"
				elsif v2.nil?
					y = Time.at(v1).year
					m = Time.at(v1).month
					d = Time.at(v1).day
					h = Time.at(v1).hour
					min = Time.at(v1).minute + 1
					return "#{y}年#{m}月#{d}日#{h}时#{min}分以后"
				else
					y1 = Time.at(v1).year
					m1 = Time.at(v1).month
					d1 = Time.at(v1).day
					h1 = Time.at(v1).hour
					min1 = Time.at(v1).minute + 1
					y2 = Time.at(v2).year
					m2 = Time.at(v2).month
					d2 = Time.at(v2).day
					h2 = Time.at(v2).hour
					min2 = Time.at(v2).minute
					return y1 == y2 && m1 == m2 && d1 == d2 ? "#{y1}年#{m1}月#{d1}日#{h1}时#{min1}分" : "#{y1}年#{m1}月#{d1}日#{h1}时#{min1}分到#{y2}年#{m2}月#{d2}日#{h2}时#{min2}分"
				end
			when 4
				# month, day
				if v1.nil?
					m = Time.at(v2).month
					d = Time.at(v2).day
					return "#{m}月#{d}日以前"
				elsif v2.nil?
					m = Time.at(v1).month
					d = Time.at(v1).day + 1
					return "#{m}月#{d}日以后"
				else
					m1 = Time.at(v1).month
					d1 = Time.at(v1).day + 1
					m2 = Time.at(v2).month
					d2 = Time.at(v2).day
					return m1 == m2 && d1 == d2 ? "#{m1}月#{d1}日" : "#{m1}月#{d1}日到#{m2}月#{d2}日"
				end
			when 5
				# hour, minute
				if v1.nil?
					h = Time.at(v2).hour
					min = Time.at(v2).minute
					return "#{h}时#{m}分以前"
				elsif v2.nil?
					h = Time.at(v1).hour
					min = Time.at(v1).minute + 1
					return "#{h}时#{m}分以后"
				else
					h1 = Time.at(v1).hour
					min1 = Time.at(v1).minute + 1
					h2 = Time.at(v2).hour
					min2 = Time.at(v2).minute
					return h1 == h2 && min1 == min2 ? "#{h1}时#{min1}分" : "#{h1}时#{min1}分到#{h2}时#{min2}分"
				end
			when 6
				# hour, minute, second
				if v1.nil?
					h = Time.at(v2).hour
					min = Time.at(v2).minute
					sec = Time.at(v2).second
					return "#{h}时#{m}分#{sec}秒以前"
				elsif v2.nil?
					h = Time.at(v1).hour
					min = Time.at(v1).minute
					sec = Time.at(v1).second + 1
					return "#{h}时#{m}分#{sec}秒以后"
				else
					h1 = Time.at(v1).hour
					min1 = Time.at(v1).minute
					sec1 = Time.at(v1).second + 1
					h2 = Time.at(v2).hour
					min2 = Time.at(v2).minute
					sec2 = Time.at(v2).second
					return h1 == h2 && min1 == min2 && sec1 == sec2 ? "#{h1}时#{min1}分#{sec1}秒" : "#{h1}时#{min1}分#{sec1}秒到#{h2}时#{min2}分#{sec2}秒"
				end
			end
		end

		def convert_time_mean_to_text(format, v)
			time = Time.at(v)
			case format
			when 0
				# year
				return "#{time.year}年"
			when 1
				# year month
				return "#{time.year}年#{time.month}月"
			when 2
				# year month day
				return "#{time.year}年#{time.month}月#{time.day}日"
			when 3
				# year month day hour minute
				return "#{time.year}年#{time.month}月#{time.day}日#{time.hour}时#{time.minute}分"
			when 4
				# month day
				return "#{time.month}月#{time.day}日"
			when 5
				# hour minute
				return "#{time.hour}时#{time.minute}分"
			when 6
				# hour minute second
				return "#{time.hour}时#{time.minute}分#{year.second}秒"
			end
		end

		def time_blank_description(analysis_result, issue, segments)
			histogram = analysis_result["histogram"]
			mean = convert_time_mean_to_text(issue.format, analysis_result["mean"])
			text = "调查显示"
			return text + "，被访者填写的平均值为#{mean}。" if segments.blank?
			interval_text_ary = []
			interval_text_ary << convert_time_interval_to_text(issue.format, nil, segments[0])
			segments[0..-2].each_with_index do |e, index|
				interval_text_ary << convert_time_interval_to_text(issue.format, e, segments[index+1])
			end
			interval_text_ary << convert_time_interval_to_text(issue.format, segments[-1], nil)
			
			results = []
			total_number = 0
			histogram.each_with_index do |number, index|
				total_number = total_number + number
				results << { "text" => interval_text_ary[index], "number" => number.to_f }
			end
			results.sort_by! { |e| -e["number"] }
			interval_text_ary = results.map { |e| e["text"] }
			ratio_ary = results.map { |e| (e["number"] * 100 / total_number).round }
			text = text + "，填写#{interval_text_ary[0]}的被访者比例最高，为#{ratio_ary[0]}%"
			# one interval
			return text + "；被访者填写的平均值为#{mean}。" if results.length == 1
			text = text + "，其次是填写#{interval_text_ary[1]}的被访者，所占比例为#{ratio_ary[1]}%"
			# two intervals
			return text + "；被访者填写的平均值为#{mean}。" if results.length == 2
			if results.length == 3
				# three intervals
				text = text + "，填写#{interval_text_ary[2]}的比例为#{ratio_ary[2]}%"
			else
				# at least four items
				interval_text_string = interval_text_ary[2..-1].join('、')
				ratio_string = (ratio_ary[2..-1].map { |e| "#{e}%" }).join('、')
				text = text + "，填写#{interval_text_string}的比例分别为#{ratio_string}"
			end

			text = text + "；被访者填写的平均值为#{mean}。"
			return text
		end

		def number_blank_description(analysis_result, issue, segments)
			histogram = analysis_result["histogram"]
			mean = analysis_result["mean"]
			text = "调查显示"
			return text + "，被访者填写的平均值为#{mean}。" if segments.blank?
			interval_text_ary = []
			interval_text_ary << "#{segments[0]}以下"
			segments[0..-2].each_with_index do |e, index|
				interval_text_ary << "#{e}到#{segments[index+1]}"
			end
			interval_text_ary << "#{segments[-1]}以上"
			
			results = []
			total_number = 0
			histogram.each_with_index do |number, index|
				total_number = total_number + number
				results << { "text" => interval_text_ary[index], "number" => number.to_f }
			end
			results.sort_by! { |e| -e["number"] }
			interval_text_ary = results.map { |e| e["text"] }
			ratio_ary = results.map { |e| (e["number"] * 100 / total_number).round }
			text = text + "，填写#{interval_text_ary[0]}的被访者比例最高，为#{ratio_ary[0]}%"
			# one interval
			return text + "；被访者填写的平均值为#{mean}。" if results.length == 1
			text = text + "，其次是填写#{interval_text_ary[1]}的被访者，所占比例为#{ratio_ary[1]}%"
			# two intervals
			return text + "；被访者填写的平均值为#{mean}。" if results.length == 2
			if results.length == 3
				# three intervals
				text = text + "，填写#{interval_text_ary[2]}的比例为#{ratio_ary[2]}%"
			else
				# at least four items
				interval_text_string = interval_text_ary[2..-1].join('、')
				ratio_string = (ratio_ary[2..-1].map { |e| "#{e}%" }).join('、')
				text = text + "，填写#{interval_text_string}的比例分别为#{ratio_string}"
			end

			text = text + "；被访者填写的平均值为#{mean}。"
			return text
		end

		def matrix_choice_description(analysis_result, issue)
			item_number = issue.items.length
			text = "调查显示，"
			# get description for each row respectively
			issue.rows.each do |row|
				row_id = row["id"]
				row_text = get_item_text_by_id(row_id)
				# obtain all the results about this row
				cur_row_analysis_result = analysis_result.select { |k, v| k.start_with?(row_id) }
				next if cur_row_analysis_result.blank?
				cur_row_results = []
				cur_row_total_number = 0
				cur_row_analysis_result.each do |k, select_number|
					item_id = k.split('-')[1]
					item_text = get_item_text_by_id(issue.items, input_id)
					next if item_text.nil?
					cur_row_total_number = cur_row_total_number + select_number.to_f
					cur_row_results << { "text" => item_text, "select_number" => select_number.to_f}
				end
				cur_row_results.sort_by! { |e| -e["select_number"] }
				item_text_ary = cur_row_results.map { |e| e["text"] }
				ratio_ary = cur_row_results.map { |e| (e["select_number"] * 100 / cur_row_total_number).round }
				# generate text for this row
				cur_row_text_ary
				item_text_ary.each_with_index do |item_text, index|
					cur_row_text_ary << "#{ratio_ary[index]}%的人对#{row_text}的选择为#{item_text}"
				end
				text = text + cur_row_text_ary.join('，') + "。"
			end
			return text
		end

		def single_choice_description(analysis_result, issue)
			total_number = 0
			results = []
			analysis_result.each do |input_id, select_number|
				item_text = get_item_text_by_id(issue.items, input_id)
				next if item_text.nil?
				total_number = total_number + select_number
				results << { "text" => item_text, "select_number" => select_number.to_f }
			end
			temp_results = results.clone
			temp_results.sort_by! { |e| -e["select_number"] }
			item_text_ary = temp_results.map { |e| e["text"] }
			ratio_ary = temp_results.map { |e| (e["select_number"] * 100 / total_number).round }
			text = "调查显示，#{ratio_ary[0]}%的人选择了#{item_text_ary[0]}"
			# only one item
			return text + "。" if temp_results.length == 1
			# two items
			return text + "，选择#{item_text_ary[1]}的比例为#{ratio_ary[1]}%。" if temp_results.length == 2
			# at least three items
			text = text + "，其次是#{item_text_ary[1]}，选择比例为#{ratio_ary[1]}%"
			if temp_results.length == 4
				# four items
				text = text + "，选择#{item_text_ary[2]}的比例为#{ratio_ary[2]}%"
			elsif temp_results.length > 4
				# at least five items
				item_text_string = item_text_ary[2..-2].join('、')
				ratio_string = (ratio_ary[2..-2].map { |e| "#{e}%" }).join('、')
				text = text + "，选择#{item_text_string}的比例分别为#{ratio_string}"
			end
			# the last item
			text = text + "。另外有#{ratio_ary[-1]}%的人选择#{item_text_ary[-1]}"
			return text
		end

		def multiple_choice_description(analysis_result, issue, answer_number, chart_type)
			# the description for multiple choice question with pie chart is exactly the same as the single choice questoin
			return single_choice_description(analysis_result, issue) if chart_type == "pie"

			results = []
			analysis_result.each do |input_id, select_number|
				item_text = get_item_text_by_id(input_id)
				next if item_text.nil?
				results << { "text" => item_text, "select_number" => select_number.to_f }
			end
			temp_results = results.clone
			temp_results.sort_by! { |e| -e["select_number"] }
			item_text_ary = temp_results.map { |e| e["text"] }
			ratio_ary = temp_results.map { |e| (e["select_number"] * 100 / answer_number).round }

			text = "调查显示，#{ratio_ary[0]}%的人选择了#{item_text_ary[0]}，所占比例最高"
			# only one item
			return text + "。" if temp_results.length == 1
			text + "，#{item_text_ary[1]}位列第二位，选择比例为#{ratio_ary[1]}%"
			# two items
			return text + "。" if temp_results.length == 2
			# three items
			return text + "，其他是#{item_text_ary[2]}（#{ratio_ary[2]}%）。" if temp_results.length == 3
			item_ratio_ary = []
			item_text_ary.each_with_index do |item_text, index|
				item_ratio_ary << "#{item_text}（#{ratio_ary[index]}%）"
			end
			item_ratio_string = item_ratio_ary.join('、')
			return text + "，其他依次是#{item_ratio_string}。"
		end

	end
end
