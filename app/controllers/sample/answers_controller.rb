# coding: utf-8
require 'array'
require 'error_enum'
require 'quill_common'
class Sample::AnswersController < ApplicationController

	before_filter :check_answer_existence, :except => [:spreaded_answer_number, :list_spreaded_answers, :index, :get_my_answer, :create, :get_today_answers_count, :get_today_spread_count]

	def check_answer_existence
		@answer = Answer.find_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if @answer.nil?
	end

	def create
		survey = Survey.normal.find_by_id(params[:survey_id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if survey.nil?
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if !params[:is_preview] && survey.status != Survey::PUBLISHED
		sample = User.sample.find_by_auth_key(params[:auth_key])
		answer = Answer.find_by_survey_id_sample_id_is_preview(params[:survey_id], sample.try(:_id), params[:is_preview] || false)
		render_json_s(answer._id.to_s) and return if !answer.nil?
		retval = survey.check_password(params[:username], params[:password], params[:is_preview] || false)
		render_json_e ErrorEnum::WRONG_SURVEY_PASSWORD if retval != true
		answer = Answer.create_answer(params[:survey_id],
			params[:reward_scheme_id],
			params[:is_preview] || false,
			params[:introducer_id],
			params[:channel],
			params[:referrer],
			params[:_remote_ip],
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
		render_json_auto @answer.clear and return
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
		render_json_auto @answer.finish and return
	end

	def show
		render_json_auto @answer.info_for_sample and return
	end

	def get_answer_id_by_auth_key
		render_json_e(ErrorEnum::REQUIRE_LOGIN) and return if @current_user.nil?
		@answer = Answer.find_by_survey_id_sample_id_is_preview(params[:survey_id], @current_user._id.to_s, params[:is_preview]||false)
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if @answer.nil?
		render_json_auto(@answer._id.to_s) and return
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

	def change_sample_account
		u = User.sample.find_by_auth_key(params[:auth_key])
		render_json_e ErrorEnum::SAMPLE_NOT_EXIST if u.nil?
		@answer.change_sample_account(u)
		render_json_s and return
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
		render_json_auto @answer.create_lottery_order(params[:order_info]) and return
	end

	#############################
	#功能:获取今日累计答题数
	#http method：get
	#传入参数: 无
	#返回的参数:答题的数量
	#############################	
	def get_today_answers_count
		date = Date.today
		today_start = Time.utc(date.year, date.month, date.day)
		today_end = Time.utc(date.year, date.month, date.day+1)
		@survey = Answer.where(:created_at.gte => today_start,:created_at.lt => today_end).count
		render_json { @survey }
	end

	#############################
	#功能:获取今日分享问卷数
	#http method：get
	#传入参数: 无
	#返回的参数:答题的数量
	############################# 
	def get_today_spread_count
		date = Date.today
		today_start = Time.utc(date.year, date.month, date.day)
		today_end = Time.utc(date.year, date.month, date.day+1)
		@survey = Answer.where(:created_at.gte => today_start,:created_at.lt => today_end,:introducer_id.ne => nil).count
		render_json { @survey }
	end

	def index
		render_json_e ErrorEnum::REQUIRE_LOGIN if @current_user.nil?
		@answers = @current_user.answers.not_preview
		@paginate_answers_info = auto_paginate @answers do |paginate_answers|
			paginate_answers.map { |e| e.info_for_answer_list_for_sample }
		end
		render_json_auto @paginate_answers_info
	end

	def list_spreaded_answers
		render_json_e ErrorEnum::REQUIRE_LOGIN and return if @current_user.nil?
		@survey = Survey.find_by_id(params[:survey_id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		@answers = @survey.answers.not_preview.where(:introducer_id => @current_user._id.to_s).desc(:status)
		@answers_info = auto_paginate @answers do |paginate_answers|
			paginate_answers.map { |e| e.info_for_spread_details }
		end
		render_json_auto @answers_info and return
	end

	def spreaded_answer_number
		render_json_e ErrorEnum::REQUIRE_LOGIN and return if @current_user.nil?
		@survey = Survey.find_by_id(params[:survey_id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		@answers = @survey.answers.not_preview.where(:introducer_id => @current_user._id.to_s)
		@total_answer_number = @answers.length
		@finished_answer_number = @answers.finished.length
		@editting_answer_number = @answers.where(:status => Answer::EDIT).length
		@spreaded_answer_number = {"total_answer_number" => @total_answer_number,
			"finished_answer_number" => @finished_answer_number,
			"editting_answer_number" => @editting_answer_number}
		render_json_auto @spreaded_answer_number and return
	end
end
