require 'error_enum'
class AnswerAuditor::AnswersController < AnswerAuditor::ApplicationController
	
	def index
		survey = @current_user.answer_auditor_allocated_surveys.find_by_id(params[:survey_id])
		render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
		render_json_auto auto_paginate(survey.answers)
	end

	def show
		answer = Answer.find_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if answer.nil?
		answer["question_content"] = []
		answer.answer_content.each do |key, val|
			# key is question id
			# val is like of { "selection" : [ NumberLong("1351400998231222"), NumberLong("3055564856809646") ], "text_input" : "" }
			question = Question.find_by_id(key)
			return ErrorEnum::QUESTION_NOT_EXIST unless question
			puts "???#{JSON.parse(question.to_json)}"
			show_answer = {}
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
			answer["question_content"] << show_answer if show_answer.count > 0
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
		retval = answer.review(params[:review_result], @current_user)
		render_json_auto(retval)
	end
end