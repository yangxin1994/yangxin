# encoding: utf-8
require 'error_enum'
class AnswersController < ApplicationController

	## before filters ##

	before_filter :check_survey_existence
	before_filter :check_answer_existence, :except => [:load_question]
	before_filter :check_answer_status, :except => [:load_question]

	def check_answer_existence
		@answer = Answer.find_by_survey_id_and_user(params[:survey_id], @current_user)
		if @answer.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
			end
		end
	end

	def check_survey_existence
		@survey = Survey.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
		if survey.publish_status != 8
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_PUBLISHED) and return }
			end
		end
	end

	def check_answer_status
		answer.update_status
		if answer.is_finish || answer.is_reject
			render_json_s([answer.status, answer.reject_type, answer.finish_type]) and return
		end
	end

	######################

	def load_question
		# 1. try to find the answer
		answer = Answer.find_by_survey_id_and_user(params[:survey_id], @current_user)
		# 2. if cannot find the answer, create new answer and check region, channel and ip quota
		if answer.nil?
			# if this is the first time that the volonteer opens this survey
			# 1. check the captcha
			render_json_e(ErrorEnum::WRONG_CAPTCHA) and return if @survey.access_control_setting["has_captcha"] && !Tool.check_captcha
			# 2. check the password
			retval = @survey.check_password
			if retval == true
				# pass the checking, create a new answer and check the region, channel, and ip quotas
				answer = Answer.create_answer(@current_user, params[:survey_id], params[:channel], params[:ip], params[:usrename], params[:password])
				render_json_auto(answer) and return if answer.class != Answer
				retval = answer.check_channel_ip_address_quota
				if retval
					# pass the check of channel, ip, and address quota, set the answer status as "edit"
					answer.set_edit
				else
					# fail to pass the check of channel, ip, and address quota, return
					render_json_auto(answer.violate_quota) and return if !retval
				end
			elsif retval.class == Answer
				# move the answer from another visitor user to the current user to let the user continue it
				render_json_auto([answer.status, answer.reject_type, answer.finish_type]) and return
			else
				# wrong password or the answer has been deleted
				render_json_auto(retval) and return
			end
		end
		# 3. now, we have an answer instance
		answer.update_status
		if answer.is_edit
			questions = answer.load_question(params[:question_id], params[:next_page])
			if answer.is_finish
				render_json_auto(questions) and return
			else
				render_json_auto([questions.to_json, answer.repeat_time]) and return
			end
		else
			render_json_auto([answer.status, answer.reject_type, answer.finish_type]) and return
		end
	end

	def clear
		retval = @answer.clear
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def submit_answer
		# 1. update the answer content
		retval = @answer.update_answer(params[:answer_type], params[:answer_content])
		render_json_auto(retval) and return if !retval

		# 2. check quality control
		if params[:answer_type] == 1
			# all quality control questions are normal questions
			retval = @answer.check_quality_control(params[:answer_content])
			render_json_auto(@answer.violate_quality_control) and return if !retval
		end

		# 3. check screen questions
		if params[:answer_type] == 1
			# all screen questions are normal questions
			retval = @answer.check_screen(params[:answer_content])
			render_json_auto(@answer.violate_screen) and return if !retval
		end

		# 4. check quota questions
		retval = @answer.check_quota_questions
		render_json_auto(@answer.violate_quota) and return if !retval

		# 5. update the logic control result
		@answer.update_logic_control_result(params[:answer_content])

		# 6. automatically finish the ansewr for those thatdo not allow pageup
		retval = @answer.auto_finish
		render_json_auto(retval) and return
	end

	def finish
		retval = @answer.finish
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
end
