# encoding: utf-8
require 'error_enum'
class AnswersController < ApplicationController
	before_filter :check_survey_existence

	def check_survey_existence
		@survey = Survey.normal.find_by_id(params[:survey_id])
		if survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end
		if survey.publish_status != 8
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_PUBLISHED and return }
			end
		end
	end

	def load_question
		# 1. try to find the answer
		answer = Answer.find_by_survey_id_and_user(params[:survey_id], @current_user)
		# 2. if cannot find the answer, create new answer and check region, channel and ip quota
		if answer.nil?
			# if this is the first time that the volonteer opens this survey
			# 1. check the captcha
			render :json => ErrorEnum::WRONG_CAPTCHA and return if @survey.quality_control_setting["has_captcha"] && !Tool.check_captcha
			# 2. check the password
			retval = @survey.check_password
			if retval == true
				# pass the checking, create a new answer and check the region, channel, and ip quotas
				answer = Answer.create_answer(@current_user, params[:survey_id], params[:channel], params[:ip], params[:usrename], params[:password])
				render :json => answer and return if answer.class != Answer
				answer.check_channel_ip_address_quota
			elsif retval.class == Answer
				# move the answer from another visitor user to the current user to let the user continue it
				answer = retval
			else
				# wrong password or the answer has been deleted
				render :json => retval and return
			end
		end
		# 3. now, we have an answer instance
		answer.update_status
		if answer.is_edit
			questions = answer.load_question(params[:question_id], params[:prev_page])
			render :json => [questions.to_json, answer.repeat_time]
		else
			render :json => [answer.status, answer.reject_type, answer.finish_type]
		end
	end

	def clear_answer
		
	end

	def submit_answer
		
	end

	def finish
		
	end
end
