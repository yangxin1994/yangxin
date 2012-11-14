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

		def self.convert_single_data(question_type, analysis_result, issue, chart_style)
			# get the type of charts needed to be generated
			chart_styles = []
			if chart_style == -1
				chart_styles = CHART_MATHCING[question_type]
			else
				chart_styles << chart_style if CHART_MATHCING[question_type].include?(chart_style)
			end
			case question_type
			when QuestionTypeEnum::BLANK_QUESTION
				return self.convert_single_blank_data(analysis_result, issue, chart_styles)
			when QuestionTypeEnum::CONST_SUM_QUESTION
				return self.convert_single_const_sum_data(analysis_result, issue, chart_styles)
			when QuestionTypeEnum::SORT_QUESTION
				return self.convert_single_sort_data(analysis_result, issue, chart_styles)
			when QuestionTypeEnum::SCALE_QUESTION
				return self.convert_single_scale_data(analysis_result, issue, chart_styles)
			end
			
		end

		def self.convert_blank_data(analysis_result, issue, chart_styles)
		end

		def self.convert_single_const_sum_data(analysis_result, issue, chart_styles)
			chart_data = []
			chart_styles.each do |chart_style|
				data = []
				items_id = issue["items"].map { |e| e["id"] }
				items_text = issue["items"].map { |e| e["content"]["text"] }
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
		end

		def self.convert_single_scale_data(analysis_result, issue, chart_styles)
			chart_data = []
			chart_styles.each do |chart_style|
				data = []
				items_id = issue["items"].map { |e| e["id"] }
				items_text = issue["items"].map { |e| e["content"]["text"] }
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
