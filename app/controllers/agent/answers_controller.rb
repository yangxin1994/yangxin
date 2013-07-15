# coding: utf-8
require 'error_enum'
require 'quill_common'
class Agent::AnswersController < Agent::ApplicationController

	before_filter :require_agent
	before_filter :check_answer_existence, :except => [:index]

	def check_answer_existence
		@answer = @agent_task.find_answer_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if @answer.nil?
	end

	def index
	end

	def show
		answer["question_content"] = []
		answer.answer_content.each do |key, val|
			# key is question id
			# val is like of { "selection" : [ NumberLong("1351400998231222"), NumberLong("3055564856809646") ], "text_input" : "" }
			question = Question.find_by_id(key)
			next unless question
			show_answer = {'question_type' => question.question_type, 
					"title" => question.content["text"]}

			case question.question_type
			when QuestionTypeEnum::CHOICE_QUESTION
				# 选择题
				# Example:
				# show_answer = {'question_type'=> 0,
				# 		'question_type_label'=> '选择题',
				# 		'title' => 'XXXXXXXXXXX',
				# 		'choices' => ['aaa', 'bbb', 'ccc'],
				# 		'selected_choices' => ['aaa', 'bbb']
				# 	}
				show_answer.merge!({'question_type_label'=> '选择题'})
				answer["question_content"] << show_answer and next if val.blank?

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
				# 		'question_type_label'=> '矩阵选择题',
				# 		'title'=>'XXXXXXXXXXX',
				# 		'choices' => ['aaa', 'bbb', 'ccc'],
				# 		'rows' => ['a1', 'a2'],
				# 		'rows_selected_choices' => [["aaa",'bbb'], ['aaa']]
				# }
				show_answer.merge!({'question_type_label'=> '矩阵选择题'})
				answer["question_content"] << show_answer and next if val.blank?

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
					(val[item['id'].to_s] || []).each do |choice_id|
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
				# 		'question_type_label'=> '文本填充题',
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => 'XXXXXXXXXXX'
				# }
				show_answer.merge!({'question_type_label'=> '文本填充题'})
				answer["question_content"] << show_answer and next if val.blank?

				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				# 数值填充题
				# Example:
				# show_answer = {'question_type' => 3 ,
				# 		'question_type_label'=> '数值填充题',
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => '23.5'
				# }	
				show_answer.merge!({'question_type_label'=> '数值填充题'})
				answer["question_content"] << show_answer and next if val.blank?

				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::EMAIL_BLANK_QUESTION
				# 邮箱题
				# Example:
				# show_answer = {'question_type' => 4 ,
				# 		'question_type_label'=> '邮箱题',
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => '23.5'
				# }	
				show_answer.merge!({'question_type_label'=> '邮箱题'})
				answer["question_content"] << show_answer and next if val.blank?

				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::URL_BLANK_QUESTION
				# 网址链接题
				# Example:
				# show_answer = {'question_type' => 5 ,
				# 		'question_type_label'=> '网址链接题',
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => 'www.baidu.com'
				# }	

				show_answer.merge!({'question_type_label'=> '网址链接题'})
				answer["question_content"] << show_answer and next if val.blank?

				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::PHONE_BLANK_QUESTION
				# 电话题
				# Example:
				# show_answer = {'question_type' => 6 ,
				# 		'question_type_label'=> '电话题',
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => '010-8888-8888'
				# }	
				show_answer.merge!({'question_type_label'=> '电话题'})
				answer["question_content"] << show_answer and next if val.blank?

				show_answer.merge!({"content"=> val.to_s})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::TIME_BLANK_QUESTION
				# 时间题
				# Example:
				# show_answer = {'question_type' => 7 ,
				# 		'question_type_label'=> '时间题',
				# 		'title'=>'XXXXXXXXXXX',
				#		'content' => '2012-01-01'
				# }	
				show_answer.merge!({'question_type_label'=> '时间题'})
				answer["question_content"] << show_answer and next if val.blank?

				show_answer.merge!({"content"=> Time.at(val.to_i/1000).strftime("%F")})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
				# 地址题
				# Example:
				# show_answer = {'question_type' => 8 ,
				# 		'question_type_label'=> '地址题',
				# 		'title'=>'XXXXXXXXXXX',	
				#		'address' => 'city-code',
				#		'detail' => 'XXXXXXXXXXXX',
				#		'postcode' => '100083',
				# }	
				show_answer.merge!({'question_type_label'=> '地址题'})
				answer["question_content"] << show_answer and next if val.blank?

				town =  QuillCommon::AddressUtility.find_province_city_town_by_code(val["address"].to_i)

				show_answer.merge!({"address"=> town, 
					"detail" => val["detail"],
					"postcode" => val["postcode"].to_i})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::BLANK_QUESTION
				# 组合填充题
				# Example:
				# show_answer = {'question_type' => 9 ,
				# 		'question_type_label'=> '组合填充题',
				# 		'title'=>'XXXXXXXXXXX',
				# 		'items' => [
				# 			{
				# 				'data_type' => 'Text',
				# 				'title' => 'XXXXXXXXXXX',
				# 				'content' => 'XX'
				# 			},
				# 			...
				# 		]
				# 	}
				show_answer.merge!({'question_type_label'=> '组合填充题'})

				questions = []
				show_answer['items'] = []
				question.issue['items'].each_with_index do |item, index|
					sub_question = {'data_type' => item['data_type'].to_s, 
						'title' => item['content']['text']}
					case item['data_type'].to_s
					when 'Text','Time','Number','Phone','Email','Url'
						sub_question.merge!({	'content'=> val[index]})
					when 'Address'
						town =  QuillCommon::AddressUtility.find_text_by_code(val[index]["address"].to_i)
						sub_question.merge!({	'content'=> 
							{
								"address"=> town, 
								"detail" => val[index]["detail"],
								"postcode" => val[index]["postcode"].to_i
							}})					
					end
					
					show_answer['items'] << sub_question
				end
				answer["question_content"] << show_answer
			when QuestionTypeEnum::MATRIX_BLANK_QUESTION
				# 
				# Example:
				# show_answer = {'question_type' => 10 ,
				# 		'question_type_label'=> '',
				# 		'title'=>'XXXXXXXXXXX',	
				show_answer.merge!({'question_type_label'=> ''})
			when QuestionTypeEnum::CONST_SUM_QUESTION
				# 比重题
				# Example:
				# show_answer = {'question_type' => 11 ,
				# 		'question_type_label'=> '比重题',
				# 		'title'=>'XXXXXXXXXXX',
				# 		'items' => [
				# 			{
				# 				'title' => 'XXXXXXXXXXX',
				# 				'content' => 'XX'
				# 			},
				# 			...
				# 		]
				# 	}
				show_answer.merge!({'question_type_label'=> '比重题'})
				answer["question_content"] << show_answer and next if val.blank?

				show_answer['items'] = []
				question.issue['items'].each do |item|
					tmp_item = {'title'=>item['content']['text']}
					tmp_item_answer = val.select{|k,v| k.to_s==item['id'].to_s}.values.first
					tmp_item.merge!({'content' => tmp_item_answer})
					show_answer['items'] << tmp_item
				end
				if question.issue['other_item'] && question.issue['other_item']['has_other_item'].to_s=='true'
					item = question.issue['other_item']['has_other_item']
					tmp_item = {'title'=>item['content']['text']}
					tmp_item_answer = val.select{|k,v| k.to_s==item['id'].to_s}.values.first
					tmp_item.merge!({'content' => tmp_item_answer})
					show_answer['items'] << tmp_item
				end

				answer["question_content"] << show_answer
			when QuestionTypeEnum::SORT_QUESTION
				# 排序题
				# Example:
				# show_answer = {'question_type' => 12 ,
				# 		'question_type_label'=> '排序题',
				# 		'title'=>'XXXXXXXXXXX',
				# 		'items' => [
				# 			{
				# 				'title' => 'XXXXXXXXXXX',
				# 			},
				# 			...
				# 		]
				# 	}
				show_answer.merge!({'question_type_label'=> '排序题'})
				answer["question_content"] << show_answer and next if val.blank?

				show_answer['items'] = []
				val['sort_result'].each do |id_s|
					item = question.issue['items'].select{|elem| elem['id'].to_s == id_s}[0]
					if item
						show_answer['items'] << {'title'=>item['content']['text']}
						next
					end
					if question.issue['other_item'] && question.issue['other_item']['has_other_item'].to_s=='true'
						item = question.issue['other_item']['has_other_item']
						show_answer['items'] << {'title'=>item['content']['text']} if item['id'].to_s == id_s
					end
				end

				answer["question_content"] << show_answer
			when QuestionTypeEnum::RANK_QUESTION
				# 
				# Example:
				# show_answer = {'question_type' => 13 ,
				# 		'question_type_label'=> '',
				# 		'title'=>'XXXXXXXXXXX',
				show_answer.merge!({'question_type_label'=> ''})
			when QuestionTypeEnum::PARAGRAPH
				# 文本段
				# Example:
				# show_answer = {'question_type' => 14 ,
				# 		'question_type_label'=> '文本段',
				# 		'title'=>'XXXXXXXXXXX',
				# 		'content' => 'XXXXXXXXXXX'
				# 	}
				show_answer.merge!({'question_type_label'=> '文本段'})
				# show_answer.merge!({"content" => val.to_s})
				answer["question_content"] << show_answer
			when QuestionTypeEnum::FILE_QUESTION	
				# 
				# Example:
				# show_answer = {'question_type' => 15 ,
				# 		'question_type_label'=> '',
				# 		'title'=>'XXXXXXXXXXX',
				show_answer.merge!({'question_type_label'=> ''})
			when QuestionTypeEnum::TABLE_QUESTION
				# 
				# Example:
				# show_answer = {'question_type' => 16 ,
				# 		'question_type_label'=> '',
				# 		'title'=>'XXXXXXXXXXX',

				show_answer.merge!({'question_type_label'=> ''})
			when QuestionTypeEnum::SCALE_QUESTION
				# 量表题
				# Example:
				# show_answer = {'question_type' =>17 ,
				# 		'question_type_label'=> '量表题',
				# 		'title'=>'XXXXXXXXXXX',
				# 		'labels' => ["很不满意", "不满意", "满意", "很满意"]
				# 		'choices' => ['aaa', 'bbb', 'ccc']
				# 		'selected_labels' => ["很不满意", "不满意", "满意"]
				# 	}
				show_answer.merge!({'question_type_label'=> '量表题'})
				answer["question_content"] << show_answer and next if val.blank?

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

		render_json_auto(answer, 
			:only => [
				:question_content, 
				:auditor_email, 
				:audit_at, 
				:audit_message, 
				:status, 
				:reject_type,
				:region])
	end

	def review
		answer = @agent_task.find_answer_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if answer.nil?
		retval = answer.agent_review(params[:review_result].to_s == "true")
		render_json_auto(retval)
	end

	def destroy
		answer = Answer.find_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if answer.nil?
		render_json_auto(answer.destroy)
	end
end