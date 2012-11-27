# coding: utf-8
require 'error_enum'
class AnswerAuditor::AnswersController < AnswerAuditor::ApplicationController
	
	def index
		if @current_user.is_admin
			survey = Survey.find_by_id(params[:survey_id])
		else
			survey = @current_user.answer_auditor_allocated_surveys.find_by_id(params[:survey_id])
		end
		render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?

		render_json_auto auto_paginate(survey.answers.where(
			status: params[:status].to_i, 
			finish_type: params[:finish_type].to_i
		)) and return if params[:status] && params[:finish_type]

		render_json_auto auto_paginate(survey.answers.where(
			status: params[:status].to_i
		)) and return if params[:status]

		render_json_auto auto_paginate(survey.answers) and return
	end

	def show
		answer = Answer.find_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if answer.nil?
		answer["question_content"] = []
		answer.answer_content.each do |key, val|
			# key is question id
			# val is like of { "selection" : [ NumberLong("1351400998231222"), NumberLong("3055564856809646") ], "text_input" : "" }
			question = Question.find_by_id(key)
			next unless question
			show_answer = {'question_type' => question.question_type, 
					"title" => question.content["text"]}

			logger.debug ">>>>>>>>>#{question.question_type}"
			case question.question_type
			when QuestionTypeEnum::CHOICE_QUESTION
				# 选择题
				# Example:
				# show_answer = {'question_type'=> 0,
				# 		'title' => 'XXXXXXXXXXX',
				# 		'choices' => ['aaa', 'bbb', 'ccc'],
				# 		'selected_choices' => ['aaa', 'bbb']
				# 	}

				if question.issue["items"] 
					choices = []
					selected_choices = []
					question.issue["items"].each do |item|
						choices << item["content"]["text"]
						val["selection"].each do |selection_id|
							selected_choices << item["content"]["text"] if selection_id.to_s == item["id"].to_s
						end
					end
					show_answer.merge!({"choices"=>choices})
					show_answer.merge!({"selected_choices"=> selected_choices})
				end
				answer["question_content"] << show_answer

			when QuestionTypeEnum::MATRIX_CHOICE_QUESTION	
				# 矩阵选择题
				# Example:
				# show_answer = {'question_type' => 1 ,
				# 		'title'=>'XXXXXXXXXXX',
				# 		'choices' => ['aaa', 'bbb', 'ccc'],
				# 		'rows' => ['a1', 'a2'],
				# 		'rows_selected_choices' => [["aaa",'bbb'], ['aaa']]
				# }

				choices = []
				rows = []
				rows_selected_choices = []

				question.issue["items"].each do |item|
					choices << item["content"]["text"]
				end
				show_answer.merge!({"choices"=>choices})
			
				question.issue['rows'].each_with_index do |item, index|
					rows << item['content']['text']
					row_selected_choices = []
					val[index].each do |choice_id|
						question.issue["items"].each do |e|
							row_selected_choices << e["content"]["text"] if choice_id.to_s == e['id'].to_s
						end
					end
					rows_selected_choices << row_selected_choices
				end
				show_answer.merge!({"rows"=>rows, "rows_selected_choices"=>rows_selected_choices})
				answer["question_content"] << show_answer

			when QuestionTypeEnum::TEXT_BLANK_QUESTION
				# 文本填充题
				# Example:
				# show_answer = {'question_type' => 2 ,
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => 'XXXXXXXXXXX'
				# }
				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer

			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				# 数值填充题
				# Example:
				# show_answer = {'question_type' => 3 ,
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => '23.5'
				# }	

				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer

			when QuestionTypeEnum::EMAIL_BLANK_QUESTION
				# 邮箱题
				# Example:
				# show_answer = {'question_type' => 4 ,
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => '23.5'
				# }	

				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer

			when QuestionTypeEnum::URL_BLANK_QUESTION
				# 网址链接题
				# Example:
				# show_answer = {'question_type' => 5 ,
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => 'www.baidu.com'
				# }	
				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer

			when QuestionTypeEnum::PHONE_BLANK_QUESTION
				# 电话题
				# Example:
				# show_answer = {'question_type' => 6 ,
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => '010-8888-8888'
				# }	
				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::TIME_BLANK_QUESTION
				# 时间题
				# Example:
				# show_answer = {'question_type' => 7 ,
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => '2012-01-01'
				# }	

				show_answer.merge!({"content"=> Time.at(val.to_s[0,10].to_i).strftime("%F")})
				answer["question_content"] << show_answer

			when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
				# 地址题
				# Example:
				# show_answer = {'question_type' => 8 ,
				# 		'title'=>'XXXXXXXXXXX',	
				#		'address' => 'city-code',
				#		'detail' => 'XXXXXXXXXXXX',
				#		'postcode' => '100083',
				# }	
				show_answer.merge!({"address"=> val["address"], 
					"detail" => val["detail"],
					"postcode" => val["postcode"]})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::BLANK_QUESTION
				# 组合填充题
				# Example:
				# show_answer = {'question_type' => 9 ,
				# 		'title'=>'XXXXXXXXXXX',
			when QuestionTypeEnum::MATRIX_BLANK_QUESTION
				# 
				# Example:
				# show_answer = {'question_type' => 10 ,
				# 		'title'=>'XXXXXXXXXXX',	
			when QuestionTypeEnum::CONST_SUM_QUESTION
				# 比重题
				# Example:
				# show_answer = {'question_type' => 11 ,
				# 		'title'=>'XXXXXXXXXXX',	
			when QuestionTypeEnum::SORT_QUESTION
				# 排序题
				# Example:
				# show_answer = {'question_type' => 12 ,
				# 		'title'=>'XXXXXXXXXXX',
			when QuestionTypeEnum::RANK_QUESTION
				# 
				# Example:
				# show_answer = {'question_type' => 13 ,
				# 		'title'=>'XXXXXXXXXXX',
			when QuestionTypeEnum::PARAGRAPH
				# 文本段
				# Example:
				# show_answer = {'question_type' => 14 ,
				# 		'title'=>'XXXXXXXXXXX',
				# 		'content' => 'XXXXXXXXXXX'
				# 	}

				show_answer.merge!({"content" => val.to_s})
				answer["question_content"] << show_answer

			when QuestionTypeEnum::FILE_QUESTION	
				# 
				# Example:
				# show_answer = {'question_type' => 15 ,
				# 		'title'=>'XXXXXXXXXXX',
			when QuestionTypeEnum::TABLE_QUESTION
				# 
				# Example:
				# show_answer = {'question_type' => 16 ,
				# 		'title'=>'XXXXXXXXXXX',
			when QuestionTypeEnum::SCALE_QUESTION
				# 量表题
				# Example:
				# show_answer = {'question_type' =>17 ,
				# 		'title'=>'XXXXXXXXXXX',
				# 		'labels' => ["很不满意", "不满意", "满意", "很满意"]
				# 		'choices' => ['aaa', 'bbb', 'ccc']
				# 		'selected_labels' => ["很不满意", "不满意", "满意"]
				# 	}

				show_answer.merge!({"labels" => question.issue["labels"]})
				if question.issue["items"] 
					choices = []
					selected_labels = []
					question.issue["items"].each do |item|
						choices << item["content"]["text"]
						val.each do |v_index, v_val|
							if v_index.to_s == item['id'].to_s
								selected_labels << question.issue["labels"][v_val.to_i] if v_val.to_i >=0
								selected_labels << "不清楚" if v_val.to_i == -1
							end
						end
					end
					show_answer.merge!({"choices"=>choices})
					show_answer.merge!({"selected_labels"=> selected_labels})
				end

				answer["question_content"] << show_answer
			end	
			
		end
		render_json_auto(answer, :only => [:question_content])
	end

	# def update
	# 	answer = Answer.find_by_id(params[:id])
	# 	render_json_auto Error::ANSWER_NOT_EXIST and return unless answer 
	# 	answer.update_attributes({finish_type: params[:finish_type].to_i})
	# 	render_json_auto answer.save
	# end

	def review
		answer = Answer.find_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if answer.nil?
		retval = answer.review(params[:review_result], @current_user, params[:message_content])
		render_json_auto(retval)
	end
end