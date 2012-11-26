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
			show_answer = {'question_type' => question.question_type}
			case question.question_type
			when QuillCommon::QuestionTypeEnum::CHOICE_QUESTION
				# Example:
				# show_answer = {'question_type'=> 0,
				# 		'title' => 'XXXXXXXXXXX',
				# 		'choices' => ['aaa', 'bbb', 'ccc'],
				# 		'selected_choices' => ['aaa', 'bbb']
				# 	}

				show_answer.merge!({"title" => question.content["text"]})
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
				# {question_content: [{title: "", choices: [], selected_choices: []}]}
				answer["question_content"] << show_answer
			when QuillCommon::QuestionTypeEnum::MATRIX_CHOICE_QUESTION	
			when QuillCommon::QuestionTypeEnum::TEXT_BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::NUMBER_BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::EMAIL_BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::URL_BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::PHONE_BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::TIME_BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::ADDRESS_BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::MATRIX_BLANK_QUESTION	
			when QuillCommon::QuestionTypeEnum::CONST_SUM_QUESTION	
			when QuillCommon::QuestionTypeEnum::SORT_QUESTION
			when QuillCommon::QuestionTypeEnum::RANK_QUESTION
			when QuillCommon::QuestionTypeEnum::PARAGRAPH
				# Example:
				# show_answer = {'question_type' => 14 ,
				# 		'title'=>'XXXXXXXXXXX',
				# 		'content' => 'XXXXXXXXXXX'
				# 	}

				show_answer.merge!({"title" => question.content["text"]})
				show_answer.merge!({"content" => val.to_s})
				answer["question_content"] << show_answer
			when QuillCommon::QuestionTypeEnum::FILE_QUESTION	
			when QuillCommon::QuestionTypeEnum::TABLE_QUESTION
			when QuillCommon::QuestionTypeEnum::SCALE_QUESTION
				# Example:
				# show_answer = {'question_type' =>17 ,
				# 		'title'=>'XXXXXXXXXXX',
				# 		'labels' => ["很不满意", "不满意", "满意", "很满意"]
				# 		'choices' => ['aaa', 'bbb', 'ccc']
				# 		'selected_labels' => ["很不满意", "不满意", "满意"]
				# 	}
				show_answer.merge!({"title" => question.content["text"]})
				show_answer.merge!({"labels" => question.issue["labels"]})
				if question.issue["items"] 
					choices = []
					selected_labels = []
					question.issue["items"].each do |item|
						choices << item["content"]["text"]
					end
					show_answer.merge!({"choices"=>choices})

					val.each do |v_index, v_val|
						selected_labels << question.issue["labels"][v_val.to_i]
					end
					show_answer.merge!({"selected_labels"=> selected_labels})
				end
			end	
			
		end
		render_json_auto(answer)
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