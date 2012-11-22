# coding: utf-8
require 'error_enum'
class AnswersController < ApplicationController

	# before_filter :require_user_exist
	before_filter :check_survey_existence, :only => [:create]
	before_filter :check_answer_existence, :except => [:get_my_answer, :create]

	before_filter :check_my_answer_existence, :only => [:load_question, :submit_answer, :clear, :finish, :destroy_preview]

	before_filter :check_ownerness_of_survey, :only => [:destroy, :show]

	def check_ownerness_of_survey
		owner = @answer.survey.user
		if @current_user.nil? || (!@current_user.is_admin && !@current_user.is_super_admin && owner != @current_user)
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
			end
		end
	end

	def check_answer_existence
		@answer = Answer.find_by_id(params[:id])
		if @answer.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
			end
		end
	end

	def check_my_answer_existence
		@answer = Answer.find_by_id(params[:id])
		owner = @answer.user
		# if the owner of the answer is a registered user, and the current user is not the owner, return ANSWER_NOT_EXIST
		if @answer.nil? || ( !owner.nil? && owner.is_registered && owner != @current_user )
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

	def create
		if !params[:is_preview] && @survey.publish_status != 8
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_PUBLISHED) and return }
			end
		end

		if @current_user
			# user already signs in
			answer = Answer.find_by_survey_id_email_is_preview(params[:survey_id], @current_user.email, params[:is_preview])
			render_json_auto(answer._id) and return if !answer.nil?
			# need to create answer
			email = @current_user.email
		else
			if params[:email].blank?
				# the survey has prize, but no email is provided
				render_json_e(ErrorEnum::REQUIRE_EMAIL_ADDRESS) and return if @survey.has_prize
				# need to create new answer
				email = nil
			else
				# obtain an user instance given the email
				user = User.find_or_create_new_visitor_by_email(params[:email])
				# return error if another registered user's email is provided
				render_json_e(ErrorEnum::WRONG_USER_EMAIL) and return if user.is_registered
				# try to get the answer the current user answers
				answer = Answer.find_by_survey_id_email_is_preview(params[:survey_id], params[:email], params[:is_preview])
				render_json_s(answer._id) and return if !answer.nil?
				# need to create new answer
				email = user.email
			end
		end

		# need to create the answer
		if params[:is_preview]
			retval = @survey.check_password_for_preview(params[:username], params[:password], @current_user)
			render_json_auto(retval) and return if retval != true
			# the first time to load questions, create the preview answer
			# answer = Answer.create_answer(params[:is_preview], @current_user, params[:survey_id], params[:channel], params[:_remote_ip], params[:username], params[:password])
			answer = Answer.create_answer(params[:is_preview], params[:introducer_id], email, params[:survey_id], params[:channel], params[:_remote_ip], params[:username], params[:password])
			render_json_auto(answer) and return if answer.class != Answer
			render_json_auto(answer._id) and return
		else
			# this is the first time that the volonteer opens this survey
			# check the password
			retval = @survey.check_password(params[:username], params[:password], @current_user)
			render_json_auto(retval) and return if retval != true
			answer = Answer.create_answer(params[:is_preview], params[:introducer_id], email, params[:survey_id], params[:channel], params[:_remote_ip], params[:username], params[:password])
			render_json_auto(answer) and return if answer.class != Answer
			answer.check_channel_ip_address_quota
			render_json_auto(answer._id) and return
		end
	end

	def load_question
		@answer.update_status	# check whether it is time out
		if @answer.is_edit
			questions = @answer.load_question(params[:question_id], params[:next_page].to_s == "true")
			if @answer.is_finish
				render_json_auto([@answer.status, @answer.reject_type, @answer.finish_type]) and return
			else
				render_json_auto([questions,
								@answer.answer_content.merge(@answer.random_quality_control_answer_content),
								@answer.survey.all_questions_id.length,
								@answer.index_of(questions),
								questions.estimate_answer_time,
								@answer.repeat_time]) and return
			end
		else
			render_json_auto([@answer.status, @answer.reject_type, @answer.finish_type]) and return
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
		passed = @answer.check_quality_control(params[:answer_content])

		# 3. check screen questions
		passed &&= @answer.check_screen(params[:answer_content]) if passed

		# 4. check quota questions (skip for previewing)
		passed &&= @answer.check_question_quota if !@answer.is_preview && passed

		# 5. update the logic control result
		@answer.update_logic_control_result(params[:answer_content]) if passed

		# 6. automatically finish the answers that do not allow pageup
		@answer.finish(true) if passed

		render_json_s and return
	end

	def finish
		retval = @answer.finish
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def show
		respond_to do |format|
			format.json	{ render_json_auto(@answer) and return }
		end
	end

	def get_my_answer
		render_json_e(ErrorEnum::REQUIRE_LOGIN) and return if @current_user.nil?
		@answer = Answer.find_by_survey_id_email_is_preview(params[:survey_id], @current_user.email, params[:is_preview])
		if @answer.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
			end
		end
		respond_to do |format|
			format.json	{ render_json_auto(@answer._id.to_s) and return }
		end
	end

	def destroy_preview
		if @answer.is_preview
			# this is a preview answer, and the owner of the answer wants to clear the answer
			@answer.survey.answers.delete(@answer)
			retval = @answer.destroy
			render_json_auto(retval) and return 
		else
			render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return
		end
	end

	def destroy
		retval = @answer.delete
		render_json_auto(retval) and return 
	end

	def estimate_remain_answer_time
		render_json_auto(@survey.estimate_answer_time) and return if @answer.nil?
		render_json_auto(@answer.estimate_remain_answer_time) and return
	end
end
