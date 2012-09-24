# coding: utf-8
require 'error_enum'
class AnswersController < ApplicationController

	before_filter :check_survey_existence
	before_filter :check_answer_existence, :except => [:load_question, :preview_load_question, :index]

	def check_answer_existence
		if !params[:preview_id].blank?
			@answer = Answer.find_by_survey_id_and_preview_id(params[:survey_id], params[:preview_id])
		else
			@answer = Answer.find_by_survey_id_and_user(params[:survey_id], @current_user)
		end
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

	######################

	def preview_load_question
		# 1. try to find the answer
		answer = Answer.find_by_survey_id_and_preview_id(params[:survey_id], params[:preview_id])
		# 2. if cannot find the answer, create new answer and check region, channel and ip quota
		if answer.nil?
			# this is the first time that the volonteer opens this survey
			# for previewing, it is not needed to check captcha, password, channel, ip, or address
			# pass the checking, create a new answer and check the region, channel, and ip quotas
			answer = Answer.create_preview_answer(params[:survey_id], params[:preview_id])
			render_json_auto(answer) and return if answer.class != Answer
			answer.set_edit
		end
		# 3. now, we have an answer instance
		answer.update_status	# check whether it is time out
		if answer.is_edit
			questions = answer.load_question(params[:question_id], params[:next_page])
			if answer.is_finish
				render_json_auto([answer.status, answer.reject_type, answer.finish_type]) and return
			else
				render_json_auto([questions.to_json, answer.repeat_time]) and return
			end
		else
			render_json_auto([answer.status, answer.reject_type, answer.finish_type]) and return
		end
	end

	def load_question
		# 1. try to find the answer
		answer = Answer.find_by_survey_id_and_user(params[:survey_id], @current_user)
		# 2. if cannot find the answer, create new answer and check region, channel and ip quota
		if answer.nil?
			# this is the first time that the volonteer opens this survey
			# 1. check the captcha
#			render_json_e(ErrorEnum::WRONG_CAPTCHA) and return if @survey.access_control_setting["has_captcha"] && !Tool.check_captcha
			# 2. check the password
			retval = @survey.check_password(params[:username], params[:password], @current_user)
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
				# render_json_auto([answer.status, answer.reject_type, answer.finish_type]) and return
				answer = retval
			else
				# wrong password or the answer has been deleted
				render_json_auto(retval) and return
			end
		end
		# 3. now, we have an answer instance
		answer.update_status	# check whether it is time out
		if answer.is_edit
			questions = answer.load_question(params[:question_id], params[:next_page])
			if answer.is_finish
				render_json_auto([answer.status, answer.reject_type, answer.finish_type]) and return
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
		# 0. check the answer's status
		render_json_e(ErrorEnum::WRONG_ANSWER_STATUS) and return if !@answer.is_edit

		# 1. update the answer content
		retval = @answer.update_answer(params[:answer_type], params[:answer_content])

		# 2. check quality control
		retval = @answer.check_quality_control(params[:answer_content])
		render_json_auto(@answer.violate_quality_control) and return if !retval

		# 3. check screen questions
		retval = @answer.check_screen(params[:answer_content])
		render_json_auto(@answer.violate_screen) and return if !retval

		# 4. check quota questions (skip for previewing)
		if !@answer.is_preview?
			retval = @answer.check_quota_questions
			render_json_auto(@answer.violate_quota) and return if !retval
		end

		# 5. update the logic control result
		@answer.update_logic_control_result(params[:answer_content])

		# 6. automatically finish the ansewr for those thatdo not allow pageup
		@answer.auto_finish

		render_json_s and return
	end

	def finish
		retval = @answer.finish
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def index
		answers = @survey.answers
		respond_to do |format|
			format.json	{ render_json_auto(answers) and return }
		end
	end

	def show
		respond_to do |format|
			format.json	{ render_json_auto(@answer) and return }
		end
	end

	def destroy
		retval = @answer.delete
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
end
