# encoding: utf-8
require 'error_enum'
require 'quill_common'
require 'array'
require 'tool'
require 'digest/md5'
require 'connect_dot_net'
class ReportResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :file_uri, :type => String

	belongs_to :survey

	def self.generate_result_key(last_update_time, answers, report_mockup, report_type, report_style)
		answer_ids = answers.map { |e| e._id.to_s }
		result_key = Digest::MD5.hexdigest(("#{last_update_time}-report-#{report_mockup.to_json}-#{report_style}-#{report_type}-#{answer_ids.to_s}"))
		return result_key
	end

	def generate_report(report_mockup, report_type, report_style, answers_transform)
		# initialize a report data instance
		report_data = Report::Data.new(report_type,
									report_mockup.title,
									report_mockup.subtitle,
									report_mockup.header,
									report_mockup.footer,
									report_mockup.author_chn,
									report_mockup.author_eng,
									report_style)
		# analyze the result based on the report mockup
		component_length = report_mockup.components.length
		last_time = Time.now.to_i
		report_mockup.components.each_with_index do |component, i|
			if component["component_type"] == 0
				# this is a single question analysis
				question_id = component["value"]["id"]
				items_com = component["value"]["items_com"]
				question_index = survey.all_questions_id.index(question_id)
				next if question_index.nil?
				report_data.push_component(1, "text" => "第#{question_index+1}题分析")
				question = BasicQuestion.find_by_id(question_id)
				if answers_transform[question_id].nil?
					cur_question_answer = []
				else
					cur_question_answer = answers_transform[question_id].delete_if { |e| e.blank? }
				end
				case question.question_type
				when QuestionTypeEnum::CHOICE_QUESTION
					analysis_result = analyze_choice(question.issue, cur_question_answer, items_com: items_com)
					# judge whether this is a single choice or multiple choice
					if question.issue["max_choice"] == 1
						text = single_choice_description(analysis_result, question.issue)
						report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
						chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																			analysis_result,
																			question.issue,
																			component["chart_style"])
						report_data.push_chart_components(chart_components)
					else
						pie_text = multiple_choice_description(analysis_result,
																question.issue,
																:answer_number => cur_question_answer.length,
																:chart_type => 'pie')
						bar_text = multiple_choice_description(analysis_result,
																question.issue,
																:answer_number => cur_question_answer.length,
																:chart_type => 'bar')
						chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																			analysis_result,
																			question.issue,
																			component["chart_style"])
						if [ChartStyleEnum::ALL, ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::STACK].include?(component["chart_style"])
							report_data.push_component(Report::Data::DESCRIPTION, "text" => pie_text)
						end
						if [ChartStyleEnum::ALL, ChartStyleEnum::LINE, ChartStyleEnum::BAR].include?(component["chart_style"])
							report_data.push_component(Report::Data::DESCRIPTION, "text" => bar_text)
						end
						report_data.push_chart_components(chart_components)
					end
				when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
					analysis_result = analyze_matrix_choice(question.issue, cur_question_answer)
					text = matrix_choice_description(analysis_result, question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																		analysis_result,
																		question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::NUMBER_BLANK_QUESTION
					segment = component["value"]["format"]["-1"]
					analysis_result = analyze_number_blank(question.issue,
														cur_question_answer,
														:segment => segment)
					segment ||= analysis_result[:segment]
					text = number_blank_description(analysis_result,
													question.issue,
													:segment => segment)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					next if segment.blank?
					chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																		analysis_result,
																		question.issue,
																		component["chart_style"],
																		:segment => segment)
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::TIME_BLANK_QUESTION
					segment = component["value"]["format"]["-1"]
					segment.map! { |v| v = v / 1000 } if !segment.blank?
					analysis_result = analyze_time_blank(question.issue,
														cur_question_answer,
														:segment => segment)
					segment ||= analysis_result[:segment]
					text = time_blank_description(analysis_result,
												question.issue,
												:segment => segment)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					next if segment.blank?
					chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																		analysis_result,
																		question.issue,
																		component["chart_style"],
																		:segment => segment)
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
					analysis_result = analyze_address_blank(question.issue,
															cur_question_answer)
					text = address_blank_description(analysis_result, question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																		analysis_result,
																		question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::BLANK_QUESTION
					analysis_result = analyze_blank(question.issue,
													cur_question_answer,
													:segment => component["value"]["format"])
					analysis_result.each do |id, sub_analysis_result|
						sub_question_item = (question.issue["items"].select { |e| e["id"].to_s == id })[0]
						sub_question_type = sub_question_item["data_type"]
						sub_question_issue = sub_question_item["properties"]
						next if sub_question_issue.nil?
						segment = component["value"]["format"].nil? ? nil : component["value"]["format"][id.to_s]
						case sub_question_type
						when "Number"
							text = number_blank_description(sub_analysis_result,
																	sub_question_issue,
																	:segment => segment)
							sub_question_type = QuestionTypeEnum::NUMBER_BLANK_QUESTION
						when "Time"
							text = time_blank_description(sub_analysis_result,
																sub_question_issue,
																:segment => segment)
							sub_question_type = QuestionTypeEnum::TIME_BLANK_QUESTION
						when "Address"
							text = address_blank_description(sub_analysis_result, sub_question_issue)
							sub_question_type = QuestionTypeEnum::ADDRESS_BLANK_QUESTION
						end
						report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
						next if [QuestionTypeEnum::NUMBER_BLANK_QUESTION, QuestionTypeEnum::TIME_BLANK_QUESTION].include?(sub_question_type) && segment.blank?
						chart_components = Report::DataAdapter.convert_single_data(sub_question_type,
																			sub_analysis_result,
																			sub_question_issue,
																			component["chart_style"],
																			:segment => segment)
						report_data.push_chart_components(chart_components)
					end
				when QuestionTypeEnum::CONST_SUM_QUESTION
					analysis_result = analyze_const_sum(question.issue, cur_question_answer, items_com: items_com)
					text = const_sum_description(analysis_result, question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																		analysis_result,
																		question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::SORT_QUESTION
					analysis_result = analyze_sort(question.issue, cur_question_answer, items_com: items_com)
					text = sort_description(analysis_result,
											question.issue,
											:answer_number => cur_question_answer.length)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																		analysis_result,
																		question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::SCALE_QUESTION
					analysis_result = analyze_scale(question.issue, cur_question_answer, items_com: items_com)
					text = scale_description(analysis_result, question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_single_data(question.question_type,
																		analysis_result,
																		question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				else
					# other types of questions are removed, the heading in the component should be removed
					report_data.pop_component
				end
			else
				question_id = component["value"]["id"]
				items_com = component["value"]["items_com"]
				target_question_id = component["value"]["target"]["id"]
				target_items_com = component["value"]["target"]["items_com"]
				question_index = survey.all_questions_id.index(question_id)
				target_question_index = survey.all_questions_id.index(target_question_id)
				next if question_index.nil? || target_question_index.nil?
				report_data.push_component(Report::Data::HEADING_2, "text" => "第#{question_index+1}题，第#{target_question_index+1}题交叉分析")

				question = BasicQuestion.find_by_id(question_id)
				target_question = BasicQuestion.find_by_id(target_question_id)
				case target_question.question_type
				when QuestionTypeEnum::CHOICE_QUESTION
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id],
													items_com: items_com,
													target_items_com: target_items_com)
					if question.issue["max_choice"] == 1
						text = cross_description("single_choice",
												analysis_result,
												question.issue,
												target_question.issue)
						report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
						chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																			analysis_result,
																			question.issue,
																			target_question.issue,
																			component["chart_style"])
						report_data.push_chart_components(chart_components)
					else
						pie_text = cross_description("multiple_choice",
												analysis_result,
												question.issue,
												target_question.issue,
												:chart_type => 'pie')
						bar_text = cross_description("multiple_choice",
												analysis_result,
												question.issue,
												target_question.issue,
												:chart_type => 'bar')
						chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																			analysis_result,
																			question.issue,
																			target_question.issue,
																			component["chart_style"])
						if [ChartStyleEnum::ALL, ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::STACK].include?(component["chart_style"])
							report_data.push_component(Report::Data::DESCRIPTION, "text" => pie_text)
						end
						if [ChartStyleEnum::ALL, ChartStyleEnum::LINE, ChartStyleEnum::BAR].include?(component["chart_style"])
							report_data.push_component(Report::Data::DESCRIPTION, "text" => bar_text)
						end
						report_data.push_chart_components(chart_components)
					end
				when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id])
					text = cross_description(target_question.question_type,
											analysis_result,
											question.issue,
											target_question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																		analysis_result,
																		question.issue,
																		target_question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::NUMBER_BLANK_QUESTION
					segment = component["value"]["target"]["format"]["-1"]
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id],
													:segment => segment)
					text = cross_description(target_question.question_type,
											analysis_result,
											question.issue,
											target_question.issue,
											:segment => segment)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					next if segment.blank?
					chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																		analysis_result,
																		question.issue,
																		target_question.issue,
																		component["chart_style"],
																		:segment => segment)
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::TIME_BLANK_QUESTION
					segment = component["value"]["target"]["format"]["-1"]
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id],
													:segment => segment)
					text = cross_description(target_question.question_type,
											analysis_result,
											question.issue,
											target_question.issue,
											:segment => segment)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					next if segment.blank?
					chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																		analysis_result,
																		question.issue,
																		target_question.issue,
																		component["chart_style"],
																		:segment => segment)
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id])
					text = cross_description(target_question.question_type,
											analysis_result,
											question.issue,
											target_question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																		analysis_result,
																		question.issue,
																		target_question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::BLANK_QUESTION
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id],
													:segment => component["value"]["target"]["format"])
					target_question.issue["items"].each do |item|
						id = item["id"]
						sub_question_type = item["data_type"]
						sub_question_issue = item["properties"]
						sub_analysis_result = {}
						sub_analysis_result[:answer_number] = analysis_result[:answer_number]
						sub_analysis_result[:result] = {}
						analysis_result[:result].each do |item_id, sub_question_result|
							sub_analysis_result[:result][item_id] = sub_question_result[id.to_s]
						end
						segment = component["value"]["target"]["format"].nil? ? nil : component["value"]["target"]["format"][id.to_s]
						case sub_question_type
						when "Number"
							sub_question_type = QuestionTypeEnum::NUMBER_BLANK_QUESTION
							text = cross_description(sub_question_type,
													sub_analysis_result,
													question.issue,
													sub_question_issue,
													:segment => component["value"]["target"]["format"][id.to_s])
						when "Time"
							sub_question_type = QuestionTypeEnum::TIME_BLANK_QUESTION
							text = cross_description(sub_question_type,
													sub_analysis_result,
													question.issue,
													sub_question_issue,
													:segment => component["value"]["target"]["format"][id.to_s])
						when "Address"
							sub_question_type = QuestionTypeEnum::ADDRESS_BLANK_QUESTION
							text = cross_description(sub_question_type,
													sub_analysis_result,
													question.issue,
													sub_question_issue)
						end
						report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
						next if [QuestionTypeEnum::TIME_BLANK_QUESTION, QuestionTypeEnum::NUMBER_BLANK_QUESTION].include?(sub_question_type) && segment.blank?
						chart_components = Report::DataAdapter.convert_cross_data(sub_question_type,
																			sub_analysis_result,
																			question.issue,
																			sub_question_issue,
																			component["chart_style"],
																			:segment => component["value"]["target"]["format"][id.to_s])
						report_data.push_chart_components(chart_components)
					end
				when QuestionTypeEnum::CONST_SUM_QUESTION
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id])
					text = cross_description(target_question.question_type,
											analysis_result,
											question.issue,
											target_question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																		analysis_result,
																		question.issue,
																		target_question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::SORT_QUESTION
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id])
					text = cross_description(target_question.question_type,
											analysis_result,
											question.issue,
											target_question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																		analysis_result,
																		question.issue,
																		target_question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				when QuestionTypeEnum::SCALE_QUESTION
					analysis_result = analyze_cross(target_question.question_type,
													question.issue,
													target_question.issue,
													answers_transform[question_id],
													answers_transform[target_question_id])
					text = cross_description(target_question.question_type,
											analysis_result,
											question.issue,
											target_question.issue)
					report_data.push_component(Report::Data::DESCRIPTION, "text" => text)
					chart_components = Report::DataAdapter.convert_cross_data(target_question.question_type,
																		analysis_result,
																		question.issue,
																		target_question.issue,
																		component["chart_style"])
					report_data.push_chart_components(chart_components)
				else
					# other types of questions are removed, the heading in the component should be removed
					report_data.pop_component
				end
			end
			if Time.now.to_i != last_time
				TaskClient.set_progress(task_id, "data_conversion_progress", (i+1).to_f / component_length)
				last_time = Time.now.to_i
			end
		end
		TaskClient.set_progress(task_id, "data_conversion_progress", 1.0 )

		logger.info "AAAAAAAAAAAAAAAAAA"
		logger.info report_data.serialize
		logger.info "AAAAAAAAAAAAAAAAAA"
		# call the webservice to generate the report
		retval = ConnectDotNet.send_data "/ExportReport.aspx" do
			{"report_data" => report_data.serialize, "job_id" => task_id}
		end
		return retval if retval.to_s.start_with?('error')
		if retval.code != "200"
			self.status = -1
			self.error_code = ErrorEnum::DOTNET_HTTP_ERROR
		elsif retval.body.start_with?('error:')
			return ErrorEnum::DOTNET_INTERNAL_ERROR
			self.status = -1
			self.error_code = ErrorEnum::DOTNET_INTERNAL_ERROR
		else
			self.status = 1
			self.file_uri = retval.body
		end
		self.save
	end

	# cross analysis and description generation
	def analyze_cross(question_type, question_issue, target_question_issue, question_answer_ary, target_question_answer_ary, opt={})
		items_com = opt[:items_com] || []
		target_items_com = opt[:target_items_com]
		opt[:items_com] = target_items_com

		# get the question items ids, with consideration if items combination
		question_items_id = question_issue["items"].map { |e| e["id"] }
		question_items_id << question_issue["other_item"]["id"] if question_issue["other_item"] && question_issue["has_other_item"]
		items_com.each do |id_ary|
			id_ary.each do |id|
				question_items_id.delete(id)
			end
			question_items_id << id_ary.join(',')
		end
		question_items_id.map! { |e| e.to_s }

		target_question_sub_answer_ary = {}
		target_question_answer_ary.each_with_index do |target_question_answer, index|
			next if target_question_answer.blank?
			question_answer = question_answer_ary[index]
			question_items_id.each do |id_string|
				id_ary = id_string.split(',')
				if !(id_ary & (question_answer["selection"].map { |e| e.to_s })).blank?
					target_question_sub_answer_ary[id_string] ||= []
					target_question_sub_answer_ary[id_string] << target_question_answer
				end
			end
		end
		result = {:answer_number => {}, :result => {}}
		question_items_id.each do |id|
			case question_type
			when QuestionTypeEnum::CHOICE_QUESTION
				result[:result][id] = analyze_choice(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
				result[:result][id] = analyze_matrix_choice(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				result[:result][id] = analyze_number_blank(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			when QuestionTypeEnum::TIME_BLANK_QUESTION
				result[:result][id] = analyze_time_blank(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
				result[:result][id] = analyze_address_blank(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			when QuestionTypeEnum::BLANK_QUESTION
				result[:result][id] = analyze_blank(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			when QuestionTypeEnum::CONST_SUM_QUESTION
				result[:result][id] = analyze_const_sum(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			when QuestionTypeEnum::SORT_QUESTION
				result[:result][id] = analyze_sort(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			when QuestionTypeEnum::SCALE_QUESTION
				result[:result][id] = analyze_scale(target_question_issue, target_question_sub_answer_ary[id] || [], opt)
			end
			result[:answer_number][id] = (target_question_sub_answer_ary[id] || []).length
		end
		return result
	end

	def cross_description(question_type, analysis_result, issue, target_issue, opt={})
		text = "调查显示："
		items = issue["items"].clone
		items << issue["other_item"] if issue["other_item"] && issue["other_item"]["has_other_item"]
		analysis_result[:result].each do |item_id, result|
			item_not_found = false
			item_id.split(',').each do |id|
				item = (items.select { |e| e["id"].to_s == id })[0]
				if item.nil?
					item_not_found = true
					break
				end
			end
			next if item_not_found
			answer_number = analysis_result[:answer_number][item_id]
			text += "没有被访者选择选择#{get_item_text_by_id(items, item_id)}。" and next if result.blank? || answer_number == 0
			text += "选择#{get_item_text_by_id(items, item_id)}的#{answer_number}名被访者中，"
			case question_type
			when "single_choice"
				text += single_choice_description(result, target_issue, opt.merge({:cross => true}))
			when "multiple_choice"
				text += multiple_choice_description(result, target_issue, opt.merge({:cross => true, :answer_number => answer_number}))
			when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
				text += matrix_choice_description(result, target_issue, opt.merge({:cross => true}))
			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				text += number_blank_description(result, target_issue, opt.merge({:cross => true}))
			when QuestionTypeEnum::TIME_BLANK_QUESTION
				text += time_blank_description(result, target_issue, opt.merge({:cross => true}))
			when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
				text += address_blank_description(result, target_issue, opt.merge({:cross => true}))
			when QuestionTypeEnum::CONST_SUM_QUESTION
				text += const_sum_description(result, target_issue, opt.merge({:cross => true}))
			when QuestionTypeEnum::SORT_QUESTION
				text += sort_description(result, target_issue, opt.merge({:cross => true, :answer_number => answer_number}))
			when QuestionTypeEnum::SCALE_QUESTION
				text += scale_description(result, target_issue, opt.merge({:cross => true}))
			end
		end
		return text
	end

	# description generation
	def scale_description(analysis_result, issue, opt={})
		results = []
		analysis_result.each do |input_id, ele|
			if ele[1] != -1
				item_text = get_item_text_by_id(issue["items"], input_id)
				next if item_text.nil?
				results << { "text" => item_text, "score" => ele[1] } 
			end
		end
		return "" if results.blank?
		results.sort_by! { |e| -e["score"] }
		item_text_ary = results.map { |e| e["text"] }
		score_ary = results.map { |e| e["score"] }
		text = opt[:cross] ? "" : "调查显示，"
		text += "#{item_text_ary[0]}的平均得分最高，为#{score_ary[0].round(1)}"
		# one item
		return text + "。" if item_text_ary.length == 1
		text = text + "，其次是#{item_text_ary[1]}，平均得分是#{score_ary[1].round(1)}"
		# two items
		return text + "。" if item_text_ary.length == 2
		# three items
		return text + "，#{item_text_ary[2]}的平均得分为#{score_ary[2].round(1)}。"
		# more than three items
		item_text_string = item_text_ary[2..-1].join('、')
		score_string = score_ary[2..-1].join('、')
		return text + "，#{item_text_string}的平均得分分别为#{score_string}。"
	end

	def sort_description(analysis_result, issue, opt={})
		answer_number = opt[:answer_number]
		return "" if answer_number == 0
		return "" if analysis_result.blank?
		first_index_dist = {}
		second_index_dist = {}
		analysis_result.each do |input_id, sort_number_ary|
			first_index_dist[input_id] = (sort_number_ary[0] * 100.0 / answer_number).round
			second_index_dist[input_id] = (sort_number_ary[1] * 100.0 / answer_number).round if sort_number_ary.length > 1
		end
		# handle the result for the first index
		first_index_results = []
		items = issue["items"].clone
		items << issue["other_item"] if issue["other_item"] && issue["other_item"]["has_other_item"]
		first_index_dist.each do |input_id, ratio|
			item_text = get_item_text_by_id(items, input_id)
			next if item_text.nil?
			first_index_results << { "text" => item_text, "ratio" => ratio }
		end
		first_index_results.sort_by! { |e| -e["ratio"] }
		first_index_item_text_ary = first_index_results.map { |e| e["text"] }
		first_index_ratio_ary = first_index_results.map { |e| e["ratio"] }
		text = opt[:cross] ? "" : "调查显示，"
		text += "将#{first_index_item_text_ary[0]}排在第一位的被访者所占比例最高，为#{first_index_ratio_ary[0].round(1)}%"
		if first_index_item_text_ary.length == 1
		elsif first_index_item_text_ary.length == 2
			text = text + "，其次是#{first_index_item_text_ary[1]}，所占比例为#{first_index_ratio_ary[1].round(1)}%"
		else
			text = text + "，其次是#{first_index_item_text_ary[1]}和#{first_index_item_text_ary[2]}，所占比例为#{first_index_ratio_ary[1].round(1)}%和#{first_index_ratio_ary[2].round(1)}%"
		end
		# handle the result for the second index
		second_index_results = []
		items = issue["items"].clone
		items << issue["other_item"] if issue["other_item"] && issue["other_item"]["has_other_item"]
		second_index_dist.each do |input_id, ratio|
			item_text = get_item_text_by_id(items, input_id)
			next if item_text.nil?
			second_index_results << { "text" => item_text, "ratio" => ratio }
		end
		second_index_results.sort_by! { |e| -e["ratio"] }
		second_index_item_text_ary = second_index_results.map { |e| e["text"] }
		second_index_ratio_ary = second_index_results.map { |e| e["ratio"] }
		return text + "。" if second_index_item_text_ary.length == 1
		text = text + "；在第二位的排序中，#{second_index_item_text_ary[0]}所占比例最高，为#{second_index_ratio_ary[0].round(1)}%"
		if second_index_item_text_ary.length == 2
			return text + "，其次是#{second_index_item_text_ary[1]}，所占比例为#{second_index_ratio_ary[1].round(1)}%。"
		else
			return text + "，其次是#{second_index_item_text_ary[1]}和#{second_index_item_text_ary[2]}，所占比例为#{second_index_ratio_ary[1].round(1)}%和#{second_index_ratio_ary[2].round(1)}%。"
		end
	end

	def const_sum_description(analysis_result, issue, opt={})
		return "" if analysis_result.blank?
		results = []
		items = issue["items"].clone
		items << issue["other_item"] if issue["other_item"] && issue["other_item"]["has_other_item"]
		analysis_result.each do |input_id, mean_weight|
			item_text = get_item_text_by_id(items, input_id)
			next if item_text.nil?
			results << { "text" => item_text, "mean_weight" => mean_weight.to_f }
		end
		results.sort_by! { |e| -e["mean_weight"] }
		item_text_ary = results.map { |e| e["text"] }
		mean_weight_ary = results.map { |e| e["mean_weight"] }
			
		text = opt[:cross] ? "" : "调查显示，"
		text += "被访者为#{item_text_ary[0]}分配的比重最高，平均为#{mean_weight_ary[0].round(1)}"
		# one item
		return text + "。" if results.length == 1
		text = text + "，其次是#{item_text_ary[1]}，所占比重为#{mean_weight_ary[1].round(1)}"
		# two items
		return text + "。" if results.length == 2
		# three items
		return text + "，#{item_text_ary[2]}所占比重为#{mean_weight_ary[2].round(1)}。" if results.length == 3
		# at least four items
		item_text_string = item_text_ary[2..-1].join('、')
		mean_weight_string = (mean_weight_ary[2..-1].map { |e| e.round(1) }).join('、')
		return text + "，#{item_text_string}所占比重分别为#{mean_weight_string}。"
	end

	def address_blank_description(analysis_result, issue, opt={})
		total_number = 0
		return "" if analysis_result.blank?
		results = []
		analysis_result.each do |region_code, number|
			address_text = QuillCommon::AddressUtility.find_text_by_code(region_code)
			number = number[0]
			next if address_text.blank?
			total_number = total_number + number
			results << { "text" => address_text, "number" => number.to_f }
		end
		return "" if total_number == 0
		results.sort_by! { |e| -e["number"] }
		address_text_ary = results.map { |e| e["text"] }
		ratio_ary = results.map { |e| (e["number"] * 100 / total_number).round }

		text = opt[:cross] ? "" : "调查显示，"
		text += "#{ratio_ary[0].round(1)}%的人填写#{address_text_ary[0]}，所占比例最高"
		# only one address
		return text + "。" if results.length == 1
		text = text + "，其次是#{address_text_ary[1]}，填写比例是#{ratio_ary[1].round(1)}"
		# two addresses
		return text + "。" if results.length == 2
		# three addresses
		return text + "，填写#{address_text_ary[2]}的比例为#{ratio_ary[2].round(1)}%。" if results.length == 3
		# four addresses
		return text + "，填写#{address_text_ary[2]}、#{address_text_ary[3]}的比例分别为#{ratio_ary[2].round(1)}%、#{ratio_ary[3].round(1)}%。" if results.length == 4
		# at least five addresses
		text = text + "，填写#{address_text_ary[2]}、#{address_text_ary[3]}、#{address_text_ary[4]}的比例分别为#{ratio_ary[2].round(1)}%、#{ratio_ary[3].round(1)}%、#{ratio_ary[4].round(1)}%"
		return text + "。" if results.length == 5
		# six addresses
		return text + "，另有#{ratio_ary[5].round(1)}%的人填写了#{address_text_ary[5]}。" if results.length == 6
		# more than six addresses
		other_ratio = 100 - ratio_array[1..4].sum
		return text + "，另有#{other_ratio.round(1)}%的人填写了其他。"
	end

	def time_blank_description(analysis_result, issue, opt={})
		segment = opt[:segment]
		histogram = analysis_result["histogram"]
		mean = convert_time_mean_to_text(issue["format"], analysis_result["mean"])
		text = opt[:cross] ? "" : "调查显示，"
		return text + "被访者填写的平均值为#{mean}。" if segment.blank?
		interval_text_ary = []
		interval_text_ary << ReportResult.convert_time_interval_to_text(issue["format"], nil, segment[0])
		segment[0..-2].each_with_index do |e, index|
			interval_text_ary << ReportResult.convert_time_interval_to_text(issue["format"], e, segment[index+1])
		end
		interval_text_ary << ReportResult.convert_time_interval_to_text(issue["format"], segment[-1], nil)
			
		results = []
		total_number = 0
		histogram.each_with_index do |number, index|
			total_number = total_number + number
			results << { "text" => interval_text_ary[index], "number" => number.to_f }
		end
		return text if total_number == 0
		results.sort_by! { |e| -e["number"] }
		interval_text_ary = results.map { |e| e["text"] }
		ratio_ary = results.map { |e| (e["number"] * 100 / total_number).round }
		text = text + "填写#{interval_text_ary[0]}的被访者比例最高，为#{ratio_ary[0].round(1)}%"
		# one interval
		return text + "；被访者填写的平均值为#{mean}。" if results.length == 1
		text = text + "，其次是填写#{interval_text_ary[1]}的被访者，所占比例为#{ratio_ary[1].round(1)}%"
		# two intervals
		return text + "；被访者填写的平均值为#{mean}。" if results.length == 2
		if results.length == 3
			# three intervals
			text = text + "，填写#{interval_text_ary[2]}的比例为#{ratio_ary[2].round(1)}%"
		else
			# at least four items
			interval_text_string = interval_text_ary[2..-1].join('、')
			ratio_string = (ratio_ary[2..-1].map { |e| "#{e.round(1)}%" }).join('、')
			text = text + "，填写#{interval_text_string}的比例分别为#{ratio_string}"
		end

		text = text + "；被访者填写的平均值为#{mean}。"
		return text
	end

	def number_blank_description(analysis_result, issue, opt={})
		segment = opt[:segment]
		histogram = analysis_result["histogram"]
		mean = analysis_result["mean"]
		text = opt[:cross] ? "" : "调查显示，"
		return text + "被访者填写的平均值为#{mean.round(1)}。" if segment.blank?
		interval_text_ary = []
		interval_text_ary << "#{segment[0]}以下"
		segment[0..-2].each_with_index do |e, index|
			interval_text_ary << "#{e}到#{segment[index+1]}"
		end
		interval_text_ary << "#{segment[-1]}以上"
			
		results = []
		total_number = 0
		histogram.each_with_index do |number, index|
			total_number = total_number + number
			results << { "text" => interval_text_ary[index], "number" => number.to_f }
		end
		return text if total_number == 0
		results.sort_by! { |e| -e["number"] }
		interval_text_ary = results.map { |e| e["text"] }
		ratio_ary = results.map { |e| (e["number"] * 100 / total_number).round }
		text = text + "填写#{interval_text_ary[0]}的被访者比例最高，为#{ratio_ary[0].round(1)}%"
		# one interval
		return text + "；被访者填写的平均值为#{mean.round(1)}。" if results.length == 1
		text = text + "，其次是填写#{interval_text_ary[1]}的被访者，所占比例为#{ratio_ary[1].round(1)}%"
		# two intervals
		return text + "；被访者填写的平均值为#{mean.round(1)}。" if results.length == 2
		if results.length == 3
			# three intervals
			text = text + "，填写#{interval_text_ary[2]}的比例为#{ratio_ary[2].round(1)}%"
		else
			# at least four items
			interval_text_string = interval_text_ary[2..-1].join('、')
			ratio_string = (ratio_ary[2..-1].map { |e| "#{e.round(1)}%" }).join('、')
			text = text + "，填写#{interval_text_string}的比例分别为#{ratio_string}"
		end

		text = text + "；被访者填写的平均值为#{mean.round(1)}。"
		return text
	end

	def matrix_choice_description(analysis_result, issue, opt={})
		item_number = issue["items"].length
		text = opt[:cross] ? "" : "调查显示，"
		# get description for each row respectively
		issue["rows"].each do |row|
			row_id = row["id"]
			row_text = get_item_text_by_id(issue["rows"], row_id.to_s)
			# obtain all the results about this row
			cur_row_analysis_result = analysis_result.select do |k, v|
				k.start_with?(row_id.to_s)
			end
			next if cur_row_analysis_result.blank?
			cur_row_results = []
			cur_row_total_number = 0
			cur_row_analysis_result.each do |k, select_number|
				item_id = k.split('-')[1]
				item_text = get_item_text_by_id(issue["items"], item_id)
				next if item_text.nil?
				cur_row_total_number = cur_row_total_number + select_number.to_f
				cur_row_results << { "text" => item_text, "select_number" => select_number.to_f}
			end
			next if cur_row_total_number == 0
			cur_row_results.sort_by! { |e| -e["select_number"] }
			item_text_ary = cur_row_results.map { |e| e["text"] }
			ratio_ary = cur_row_results.map { |e| (e["select_number"] * 100 / cur_row_total_number).round }
			# generate text for this row
			cur_row_text_ary = []
			item_text_ary.each_with_index do |item_text, index|
				cur_row_text_ary << "#{ratio_ary[index].round(1)}%的人对#{row_text}的选择为#{item_text}"
			end
			text = text + cur_row_text_ary.join('，') + "。"
		end
		return text
	end

	def single_choice_description(analysis_result, issue, opt={})
		total_number = 0
		results = []
		items = issue["items"].clone
		items << issue["other_item"] if issue["other_item"] && issue["other_item"]["has_other_item"]
		analysis_result.each do |input_id, select_number|
			item_text = get_item_text_by_id(items, input_id)
			next if item_text.nil?
			total_number = total_number + select_number
			results << { "text" => item_text, "select_number" => select_number.to_f }
		end
		return "" if total_number == 0
		temp_results = results.clone
		temp_results.sort_by! { |e| -e["select_number"] }
		item_text_ary = temp_results.map { |e| e["text"] }
		ratio_ary = temp_results.map { |e| (e["select_number"] * 100 / total_number).round }
		text = opt[:cross] ? "" : "调查显示，"
		text = text + "#{ratio_ary[0].round(1)}%的人选择了#{item_text_ary[0]}"
		# only one item
		return text + "。" if temp_results.length == 1
		# two items
		return text + "，选择#{item_text_ary[1]}的比例为#{ratio_ary[1].round(1)}%。" if temp_results.length == 2
		# at least three items
		text = text + "，其次是#{item_text_ary[1]}，选择比例为#{ratio_ary[1].round(1)}%"
		if temp_results.length == 4
			# four items
			text = text + "，选择#{item_text_ary[2]}的比例为#{ratio_ary[2].round(1)}%"
		elsif temp_results.length > 4
			# at least five items
			item_text_string = item_text_ary[2..-2].join('、')
			ratio_string = (ratio_ary[2..-2].map { |e| "#{e.round(1)}%" }).join('、')
			text = text + "，选择#{item_text_string}的比例分别为#{ratio_string}"
		end
		# the last item
		text = text + "。另外有#{ratio_ary[-1].round(1)}%的人选择#{item_text_ary[-1]}"
		return text
	end

	def multiple_choice_description(analysis_result, issue, opt={})
		answer_number = opt[:answer_number]
		return "" if answer_number == 0
		chart_type = opt[:chart_type]
		# the description for multiple choice question with pie chart is exactly the same as the single choice question
		return single_choice_description(analysis_result, issue, opt) if chart_type == "pie"
		results = []
		items = issue["items"].clone
		items << issue["other_item"] if issue["other_item"] && issue["other_item"]["has_other_item"]
		analysis_result.each do |input_id, select_number|
			item_text = get_item_text_by_id(items, input_id)
			next if item_text.nil?
			results << { "text" => item_text, "select_number" => select_number.to_f }
		end
		temp_results = results.clone
		temp_results.sort_by! { |e| -e["select_number"] }
		item_text_ary = temp_results.map { |e| e["text"] }
		ratio_ary = temp_results.map { |e| (e["select_number"] * 100 / answer_number).round }
		text = opt[:cross] ? "" : "调查显示，"
		text = text + "#{ratio_ary[0].round(1)}%的人选择了#{item_text_ary[0]}，所占比例最高"
		# only one item
		return text + "。" if temp_results.length == 1
		text += "，#{item_text_ary[1]}位列第二位，选择比例为#{ratio_ary[1].round(1)}%"
		# two items
		return text + "。" if temp_results.length == 2
		# three items
		return text + "，其他是#{item_text_ary[2]}（#{ratio_ary[2].round(1)}%）。" if temp_results.length == 3
		item_ratio_ary = []
		item_text_ary[2..-1].each_with_index do |item_text, index|
			item_ratio_ary << "#{item_text}（#{ratio_ary[index+2].round(1)}%）"
		end
		item_ratio_string = item_ratio_ary.join('、')
		return text + "，其他依次是#{item_ratio_string}。"
	end

	# tools
	def get_item_text_by_id(items, id)
		ids = id.split(',')
		selected_items = items.select { |e| ids.include?(e["id"].to_s) }
		return nil if selected_items.blank?
		item_text_ary = selected_items.map { |item| item["content"]["text"] }
		item_text = item_text_ary.join('或')
		return item_text
	end

	def self.convert_time_interval_to_text(format, v1, v2)
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
				min = Time.at(v2).min
				return "#{y}年#{m}月#{d}日#{h}时#{min}分以前"
			elsif v2.nil?
				y = Time.at(v1).year
				m = Time.at(v1).month
				d = Time.at(v1).day
				h = Time.at(v1).hour
				min = Time.at(v1).min + 1
				return "#{y}年#{m}月#{d}日#{h}时#{min}分以后"
			else
				y1 = Time.at(v1).year
				m1 = Time.at(v1).month
				d1 = Time.at(v1).day
				h1 = Time.at(v1).hour
				min1 = Time.at(v1).min + 1
				y2 = Time.at(v2).year
				m2 = Time.at(v2).month
				d2 = Time.at(v2).day
				h2 = Time.at(v2).hour
				min2 = Time.at(v2).min
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
				min = Time.at(v2).min
				return "#{h}时#{min}分以前"
			elsif v2.nil?
				h = Time.at(v1).hour
				min = Time.at(v1).min + 1
				return "#{h}时#{min}分以后"
			else
				h1 = Time.at(v1).hour
				min1 = Time.at(v1).min + 1
				h2 = Time.at(v2).hour
				min2 = Time.at(v2).min
				return h1 == h2 && min1 == min2 ? "#{h1}时#{min1}分" : "#{h1}时#{min1}分到#{h2}时#{min2}分"
			end
		when 6
			# hour, minute, second
			if v1.nil?
				h = Time.at(v2).hour
				min = Time.at(v2).min
				sec = Time.at(v2).second
				return "#{h}时#{min}分#{sec}秒以前"
			elsif v2.nil?
				h = Time.at(v1).hour
				min = Time.at(v1).min
				sec = Time.at(v1).second + 1
				return "#{h}时#{min}分#{sec}秒以后"
			else
				h1 = Time.at(v1).hour
				min1 = Time.at(v1).min
				sec1 = Time.at(v1).second + 1
				h2 = Time.at(v2).hour
				min2 = Time.at(v2).min
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
			return "#{time.year}年#{time.month}月#{time.day}日#{time.hour}时#{time.min}分"
		when 4
			# month day
			return "#{time.month}月#{time.day}日"
		when 5
			# hour minute
			return "#{time.hour}时#{time.min}分"
		when 6
			# hour minute second
			return "#{time.hour}时#{time.min}分#{year.second}秒"
		end
	end

end
