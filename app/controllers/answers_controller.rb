# encoding: utf-8
require 'error_enum'
class AnswersController < ApplicationController

	before_filter :check_survey_existence, :except => [:show, :get_my_answer, :destroy]
	before_filter :check_answer_existence, :except => [:show, :get_my_answer, :destroy, :start, :estimate_remain_answer_time]

	def check_answer_existence
		@answer = Answer.find_by_survey_id_user_is_preview(params[:survey_id], @current_user, params[:is_preview])
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
	end

	######################

	def start
		if !params[:is_preview] && @survey.publish_status != 8
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_PUBLISHED) and return }
			end
		end
		
		answer = Answer.find_by_survey_id_user_is_preview(params[:survey_id], @current_user, params[:is_preview])
		# the answer already exists
		render_json_auto(answer._id) and return if !answer.nil?

		# need to create the answer
		if params[:is_preview]
			retval = @survey.check_password_for_preview(params[:username], params[:password], @current_user)
			if retval == true
				# the first time to load questions, create the preview answer
				answer = Answer.create_answer(params[:is_preview], @current_user, params[:survey_id], params[:channel], params[:ip], params[:username], params[:password])
				render_json_auto(answer) and return if answer.class != Answer
				answer.set_edit
				render_json_auto(answer._id) and return
			else
				# wrong password
				render_json_auto(retval) and return
			end
		else
			# this is the first time that the volonteer opens this survey
			# 1. check the captcha
			#	render_json_e(ErrorEnum::WRONG_CAPTCHA) and return if @survey.access_control_setting["has_captcha"] && !Tool.check_captcha
			# 2. check the password
			retval = @survey.check_password(params[:username], params[:password], @current_user)
			if retval == true
				# pass the checking, create a new answer and check the region, channel, and ip quotas
				answer = Answer.create_answer(params[:is_preview], @current_user, params[:survey_id], params[:channel], params[:ip], params[:username], params[:password])
				render_json_auto(answer) and return if answer.class != Answer
				retval = answer.check_channel_ip_address_quota
				if retval
					# pass the check of channel, ip, and address quota, set the answer status as "edit"
					answer.set_edit
					render_json_auto(answer._id) and return
				else
					# fail to pass the check of channel, ip, and address quota, return
					render_json_auto(answer.violate_quota) and return if !retval
				end
			else
				# wrong password
				render_json_auto(retval) and return
			end
		end
	end

	def load_question
		if !params[:is_preview] && @survey.publish_status != 8
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_PUBLISHED) and return }
			end
		end
		# 1. try to find the answer
		answer = Answer.find_by_survey_id_user_is_preview(params[:survey_id], @current_user, params[:is_preview])
		# 2. if cannot find the answer, return error code
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if answer.nil?
		# now, we have an answer instance
		answer.update_status	# check whether it is time out
		if answer.is_edit
			questions = answer.load_question(params[:question_id], params[:next_page])
			if answer.is_finish
				render_json_auto([answer.status, answer.reject_type, answer.finish_type]) and return
			elsif questions.class == String && questions.start_with?("error")
				render_json_e(questions) and return
			else
				render_json_auto([questions, answer.answers_of(questions), answer.question_number, answer.index_of(questions), questions.estimate_answer_time, answer.repeat_time]) and return
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
		retval = @answer.update_answer(params[:answer_content])

		# 2. check quality control
		retval = @answer.check_quality_control(params[:answer_content])
		render_json_auto(@answer.violate_quality_control) and return if !retval

		# 3. check screen questions
		retval = @answer.check_screen(params[:answer_content])
		render_json_auto(@answer.violate_screen) and return if !retval

		# 4. check quota questions (skip for previewing)
		if !@answer.is_preview
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

	def show
		@survey = @current_user.is_admin ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
		@answer = @survey.answers.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
			end
		end
		respond_to do |format|
			format.json	{ render_json_auto(@answer) and return }
		end
	end

	def get_my_answer
		@answer = Answer.find_by_survey_id_user_is_preview(params[:survey_id], @current_user, params[:is_preview])
		if @answer.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
			end
		end
		respond_to do |format|
			format.json	{ render_json_auto(@answer) and return }
		end
	end

	def destroy
		if params[:is_preview]
			@answer = Answer.find_by_survey_id_user_is_preview(params[:survey_id], @current_user, params[:is_preview])
			if @answer.nil?
				respond_to do |format|
					format.json	{ render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
				end
			end
			retval = @answer.destroy
			respond_to do |format|
				format.json	{ render_json_auto(retval) and return }
			end
		else
			@survey = @current_user.is_admin ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
			if @survey.nil?
				respond_to do |format|
					format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
				end
			end
			@answer = @survey.answers.find_by_id(params[:id])
			if @answer.nil?
				respond_to do |format|
					format.json	{ render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
				end
			end
			retval = @answer.delete
			respond_to do |format|
				format.json	{ render_json_auto(retval) and return }
			end
		end
	end

	def estimate_remain_answer_time
		answer = Answer.find_by_survey_id_user_is_preview(params[:survey_id], @current_user, params[:is_preview])
		render_json_auto(@survey.estimate_answer_time) and return if answer.nil?
		render_json_auto(answer.estimate_remain_answer_time) and return
	end
end
