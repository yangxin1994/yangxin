# coding: utf-8
require 'error_enum'
require 'quill_common'
class AnswersController < ApplicationController

	# before_filter :require_user_exist
	# before_filter :check_survey_existence, :only => [:create]
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
		survey = Survey.normal.find_by_id(params[:survey_id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if survey.nil?
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if !is_preivew && survey.publish_status != QuillCommon::PublishStatusEnum::PUBLISHED
		sample = User.sample.find_by_email_mobile(params[:email_mobile])
		answer = Answer.find_by_survey_id_sample_id_is_preview(params[:survey_id], params[:sample_id], params[:is_preview])
		render_json_s(answer._id.to_s) and return if !answer.nil?
		retval = survey.check_password(username, password, is_preview)
		render_json_e ErrorEnum::WRONG_SURVEY_PASSWORD if retval != true
		answer = Answer.create_answer(params[:survey_id],
			params[:reward_scheme_id],
			params[:is_preview],
			params[:introducer_id],
			params[:channel],
			params[:referrer],
			params[:remote_ip],
			params[:username],
			params[:password])
		sample.answers << answer if !sample.nil?
		answer.check_channel_ip_address_quota
		render_json_auto answer._id.to_s and return
	end

	def load_question
		@answer.update_status	# check whether it is time out
		if @answer.is_edit
			questions = @answer.load_question(params[:question_id], params[:next_page].to_s == "true")
			question_ids = questions.map { |e| e._id.to_s }
			if @answer.is_finish
				render_json_auto([@answer.status, @answer.reject_type, @answer.audit_message]) and return
			else
				answers = @answer.answer_content.merge(@answer.random_quality_control_answer_content)
				answers = answers.select { |k, v| question_ids.include?(k) }
				render_json_auto([questions,
								answers,
								@answer.survey.all_questions_id(false).length + @answer.random_quality_control_answer_content.length,
								@answer.index_of(questions),
								questions.estimate_answer_time,
								@answer.repeat_time]) and return
			end
		else
			render_json_auto([@answer.status, @answer.reject_type, @answer.audit_message]) and return
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

	def get_reward_info
		respond_to do |format|
			format.json	{ render_json_auto({reward: @answer.reward, point: @answer.point, lottery_id: @answer.lottery_id.to_s}) and return }
		end
	end

	def get_my_answer_by_id
		respond_to do |format|
			format.json	{ render_json_auto({survey_id: @answer.survey_id.to_s,
											is_preview: @answer.is_preview,
											reward_type: @answer.reward,
											point: @answer.point,
											lottery_id: @answer.lottery_id.to_s,
											lottery_title: @answer.lottery.try(:title)}) and return }
		end
	end

	def get_my_answer
		render_json_e(ErrorEnum::REQUIRE_LOGIN) and return if @current_user.nil?
		@answer = Answer.find_by_survey_id_email_is_preview(params[:survey_id], @current_user.email, params[:is_preview])
		if @answer.nil?
			respond_to do |format|
				format.json  { render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return }
			end
		end
		respond_to do |format|
			format.json  { render_json_auto(@answer) and return }
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



	def change_sample_account
		login = User.login_with_email_mobile(params[:email_mobile], params[:password], @remote_ip, params[:_client_type], false, nil)
		u = User.find_by_auth_key(login["auth_key"])
		@answer.change_sample_account(u)
		render_json_auto login and return
	end

	def logout
		render_json_auto @answer.logout_sample_account and return
	end

	def select_reward
		render_json_auto @answer.select_reward(params[:reward_index], params[:mobile], params[:alipay_account]) and return
	end

	def bind_sample
		render_json_auto @answer.bind_sample(params[:email_mobile]) and return
	end

	def draw_lottery
		render_json_auto @answer.draw_lottery and return
	end

	def create_lottery_order
		
	end
end
