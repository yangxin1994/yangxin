# encoding: utf-8
module Jobs
	class ReportDataAdapter

		CHART_MATHCING = {
			QuestionTypeEnum::CHOICE_QUESTION => [ChartStyleEnum::PIE,
												ChartStyleEnum::DOUGHNUT,
												ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
			QuestionTypeEnum::MATRIX_CHOICE_QUESTION => [ChartStyleEnum::PIE,
												ChartStyleEnum::DOUGHNUT,
												ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
			QuestionTypeEnum::NUMBER_BLANK_QUESTION => [ChartStyleEnum::PIE,
												ChartStyleEnum::DOUGHNUT,
												ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
			QuestionTypeEnum::TIME_BLANK_QUESTION => [ChartStyleEnum::PIE,
												ChartStyleEnum::DOUGHNUT,
												ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
			QuestionTypeEnum::ADDRESS_BLANK_QUESTION => [ChartStyleEnum::PIE,
												ChartStyleEnum::DOUGHNUT,
												ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
			QuestionTypeEnum::BLANK_QUESTION => [ChartStyleEnum::PIE,
												ChartStyleEnum::DOUGHNUT,
												ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
			QuestionTypeEnum::CONST_SUM_QUESTION => [ChartStyleEnum::PIE,
												ChartStyleEnum::DOUGHNUT,
												ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
			QuestionTypeEnum::SORT_QUESTION => [ChartStyleEnum::PIE,
												ChartStyleEnum::DOUGHNUT,
												ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
			QuestionTypeEnum::SCALE_QUESTION => [ChartStyleEnum::LINE,
												ChartStyleEnum::BAR,
												ChartStyleEnum::STACK],
		}

		def self.convert_single_data(question_type, analysis_result, issue, chart_style, opt = {})
			# get the type of charts needed to be generated
			chart_styles = []
			if chart_style == -1
				chart_styles = CHART_MATHCING[question_type]
			else
				chart_styles << chart_style if CHART_MATHCING[question_type].include?(chart_style)
			end
			case question_type
			when QuestionTypeEnum::CHOICE_QUESTION
				return self.convert_single_choice_data(analysis_result, issue, chart_styles)
			when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
				return self.convert_single_matrix_choice_data(analysis_result, issue, chart_styles)
			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				return self.convert_single_number_blank_data(analysis_result, issue, chart_styles, opt["format"] || [])
			when QuestionTypeEnum::TIME_BLANK_QUESTION
				return self.convert_single_time_blank_data(analysis_result, issue, chart_styles, opt["format"] || [])
			when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
				return self.convert_single_address_blank_data(analysis_result, issue, chart_styles)
			when QuestionTypeEnum::CONST_SUM_QUESTION
				return self.convert_single_const_sum_data(analysis_result, issue, chart_styles)
			when QuestionTypeEnum::SORT_QUESTION
				return self.convert_single_sort_data(analysis_result, issue, chart_styles)
			when QuestionTypeEnum::SCALE_QUESTION
				return self.convert_single_scale_data(analysis_result, issue, chart_styles)
			end
		end

		def self.convert_single_choice_data(analysis_result, issue, chart_styles)
			chart_data = []
			items_id = issue["items"].map { |e| e["id"] }
			items_text = issue["items"].map { |e| e["content"]["text"] }
			if issue["other_item"] && issue["other_item"]["has_other_item"]
				items_id << issue["other_item"]["id"]
				items_text << issue["other_item"]["content"]["text"]
			end
			chart_styles.each do |chart_style|
				data = []
				if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE].include?(chart_style)
					# multipe categories, one series
					data << ["Categories"] + items_text
					number = items_id.map { |id| analysis_result[id] || 0 }
					data << ["选择人数"] + number
				elsif chart_style == ChartStyleEnum::STACK
					# one category, multiple series
					data << ["Categories"] + "选择人数"
					items_id.each_with_index do |id, index|
						data << [items_text[index], analysis_result[id] || 0]
					end
				end
				chart_data << [chart_style, data] if !data.blank?
			end
			return chart_data
		end

		def self.convert_single_matrix_choice_data(analysis_result, issue, chart_styles, segments)

		end

		def self.convert_single_number_blank_data(analysis_result, issue, chart_styles, segments)
			chart_data = []
			histogram = analysis_result["histogram"]
			interval_text_ary = []
			interval_text_ary << "#{segments[0]}以下"
			segments[0..-2].each_with_index do |e, index|
				interval_text_ary << "#{e}到#{segments[index+1]}"
			end
			interval_text_ary << "#{segments[-1]}以上"
			chart_styles.each do |chart_style|
				data = []
				if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE].include?(chart_style)
					# multipe categories, one series
					data << ["Categories"] + interval_text_ary
					data << ["数量"] + histogram
				elsif chart_style == ChartStyleEnum::STACK
					# one category, multiple series
					data << ["Categories"] + "数量"
					interval_text_ary.each_with_index do |text, index|
						data << [text, histogram[index]]
					end
				end
				chart_data << [chart_style, data] if !data.blank?
			end
			return chart_data
		end

		def self.convert_single_time_blank_data(analysis_result, issue, chart_styles, segments)
			chart_data = []
			interval_text_ary = []
			interval_text_ary << ReportJob.convert_time_interval_to_text(issue.format, nil, segments[0])
			segments[0..-2].each_with_index do |e, index|
				interval_text_ary << ReportJob.convert_time_interval_to_text(issue.format, e, segments[index+1])
			end
			interval_text_ary << ReportJob.convert_time_interval_to_text(issue.format, segments[-1], nil)
			histogram = histogram = analysis_result["histogram"]
			chart_styles.each do |chart_style|
				data = []
				if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE].include?(chart_style)
					# multipe categories, one series
					data << ["Categories"] + interval_text_ary
					data << ["数量"] + histogram
				elsif chart_style == ChartStyleEnum::STACK
					# one category, multiple series
					data << ["Categories"] + "数量"
					interval_text_ary.each_with_index do |text, index|
						data << [text, histogram[index]]
					end
				end
				chart_data << [chart_style, data] if !data.blank?
			end
			return chart_data
		end

		def self.convert_single_address_blank_data(analysis_result, issue, chart_styles)
			address_text = []
			answer_number = []
			analysis_result.each do |region_code, number|
				text = Address.find_text_by_code(region_code)
				next if _text.blank?
				address_text << text
				answer_number << number
			end
			chart_data = []
			chart_styles.each do |chart_style|
				data = []
				if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE].include?(chart_style)
					# multipe categories, one series
					data << ["Categories"] + address_text
					data << ["数量"] + answer_number
				elsif chart_style == ChartStyleEnum::STACK
					# one category, multiple series
					data << ["Categories"] + "数量"
					address_text.each_with_index do |text, index|
						data << [text, answer_number[index]]
					end
				end
				chart_data << [chart_style, data] if !data.blank?
			end
			return chart_data
		end

		def self.convert_single_const_sum_data(analysis_result, issue, chart_styles)
			chart_data = []
			items_id = issue["items"].map { |e| e["id"] }
			items_text = issue["items"].map { |e| e["content"]["text"] }
			if issue["other_item"] && issue["other_item"]["has_other_item"]
				items_id << issue["other_item"]["id"]
				items_text << issue["other_item"]["content"]["text"]
			end
			chart_styles.each do |chart_style|
				data = []
				if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE].include?(chart_style)
					# multipe categories, one series
					data << ["Categories"] + items_text
					score = items_id.map { |id| analysis_result[id] }
					data << ["平均比重"] + score
				elsif chart_style == ChartStyleEnum::STACK
					# one category, multiple series
					data << ["Categories"] + "平均比重"
					items_id.each_with_index do |id, index|
						data << [items_text[index], analysis_result[id]]
					end
				end
				chart_data << [chart_style, data] if !data.blank?
			end
			return chart_data
		end

		def self.convert_single_sort_data(analysis_result, issue, chart_styles)
			chart_data = []
			items_id = issue["items"].map { |e| e["id"] }
			items_text = issue["items"].map { |e| e["content"]["text"] }
			if issue["other_item"] && issue["other_item"]["has_other_item"]
				items_id << issue["other_item"]["id"]
				items_text << issue["other_item"]["content"]["text"]
			end
			order_number = (analysis_result.map { |e| e.length }).max
			order_text = []
			1.upto(order_number) do |e|
				order_text << "第{e}位"
			end
			chart_styles.each do |chart_style|
				data = []
				if [ChartStyleEnum::BAR, ChartStyleEnum::LINE].include?(chart_style)
					# multipe categories, one series
					data << ["Categories"] + order_text
					1.upto(order_number) do |e|
						number = Array.new(order_number, 0)
						analysis_result[items_id[e-1]].each_with_index do |e, index|
							number[index] = e
						end
						data << items_text[e-1] + number
					end
				elsif chart_style == ChartStyleEnum::STACK
					# one category, multiple series
					data << ["Categories"] + items_text
					1.upto(order_number) do |e|
						order_result = []
						items_id.each do |id|
							order_result << analysis_result[id][e-1] || 0
						end
						data << ["第#{e}位", order_result]
					end
				elsif [ChartStyleEnum::BAR, ChartStyleEnum::DOUGHNUT].include?(chart_style)
					# the propotion for the first order
					data << ["Categories"] + items_text
					times = items_id.map { |id| analysis_result[id][0] }
					data << ["第1位"] + times
				end
				chart_data << [chart_style, data] if !data.blank?
			end
			return chart_data
		end

		def self.convert_single_scale_data(analysis_result, issue, chart_styles)
			chart_data = []
			items_id = issue["items"].map { |e| e["id"] }
			items_text = issue["items"].map { |e| e["content"]["text"] }
			chart_styles.each do |chart_style|
				data = []
				if [ChartStyleEnum::BAR, ChartStyleEnum::LINE].include?(chart_style)
					# multipe categories, one series
					data << ["Categories"] + items_text
					score = items_id.map { |id| analysis_result[id][1] }
					data << ["分数"] + score
				elsif chart_style == ChartStyleEnum::STACK
					# one category, multiple series
					data << ["Categories"] + "分数"
					items_id.each_with_index do |id, index|
						data << [items_text[index], analysis_result[id][1]]
					end
				end
				chart_data << [chart_style, data] if !data.blank?
			end
			return chart_data
		end

	end
end
