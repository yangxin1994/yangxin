# finish migrating
require 'array'
class Filler::AnswersController < Filler::FillerController
	
	# AJAX
	def create
		# hack: if the cookie has already has an answer_id and is not signed in, return the answer_id
		# Used to avoid creating multiple answers when user click the back key in the keyboard when answeing survey
		if !user_signed_in
			answer_id = cookies[cookie_key(params[:survey_id], params[:is_preview])]
			render_json_auto answer_id and return if answer_id.present?
		end

		survey = Survey.normal.find_by_id(params[:survey_id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if survey.nil?
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if !params[:is_preview] && survey.status != Survey::PUBLISHED
		render_json_e ErrorEnum::MAX_NUM_PER_IP_REACHED and return if survey.max_num_per_ip_reached?(request.remote_ip)
		answer = Answer.find_by_survey_id_sample_id_is_preview(params[:survey_id], current_user.try(:_id), params[:is_preview] || false)
		render_json_s(answer._id.to_s) and return if !answer.nil?
		retval = survey.check_password(params[:username], params[:password], params[:is_preview] || false)
		render_json_e ErrorEnum::WRONG_SURVEY_PASSWORD and return if retval != true
		answer = Answer.create_answer(params[:survey_id],
			params[:reward_scheme_id],
			params[:is_preview] || false,
			params[:introducer_id],
			params[:agent_task_id],
			params[:channel],
			params[:referrer],
			request.remote_ip,
			params[:username],
			params[:password],
			request.env['HTTP_USER_AGENT'] )
		current_user.answers << answer if current_user.present?
		answer.check_channel_ip_address_quota
		if !user_signed_in
			# If a new answer for the survey is created, and the user is not signed in
			# store the answer id in the cookie
			cookies[cookie_key(params[:survey_id], params[:is_preview])] = { 
				:value => answer._id.to_s, 
				:expires => Rails.application.config.answer_id_time_out_in_hours.hours.from_now ,
				:domain => :all
			}
		end
		render_json_auto answer._id.to_s
	end

	# PAGE
	def show
		# get answer
		@answer = Answer.find_by_id(params[:id])
		render_404 if @answer.nil?

		# load data
		redirect_to sign_in_path({ref: request.url}) and return if @answer.user.present? && @answer.user != current_user
		@answer.update_status	# check whether it is time out
		if @answer.is_edit
			questions = @answer.load_question(nil, true)
			question_ids = questions.map { |e| e._id.to_s }
			if @answer.is_finish
				retval = {"answer_status" => @answer.status,
					"answer_reject_type" => @answer.reject_type,
					"answer_audit_message" => @answer.audit_message,
					"order_id" => @answer.order.try(:id),
					"order_code" => @answer.order.try(:code),
					"order_status" => @answer.order.try(:status)}
			else
				answers = @answer.answer_content.merge(@answer.random_quality_control_answer_content)
				answers = answers.select { |k, v| question_ids.include?(k) }
				retval = {"answer_status" => @answer.status,
					"questions" => questions,
					"answers" => answers,
					"question_number" => @answer.survey.all_questions_id(false).length + @answer.random_quality_control_answer_content.length,
					"answer_index" => @answer.index_of(questions),
					"estimate_answer_time" => questions.estimate_answer_time,
					"repeat_time" => @answer.repeat_time,
					"order_id" => @answer.order.try(:_id),
					"order_code" => @answer.order.try(:code),
					"order_status" => @answer.order.try(:status)}
			end
		else
			retval = {"answer_status" => @answer.status,
				"answer_reject_type" => @answer.reject_type,
				"answer_audit_message" => @answer.audit_message,
				"order_id" => @answer.order.try(:_id),
				"order_code" => @answer.order.try(:code),
				"order_status" => @answer.order.try(:status)}
		end
		@data = {:success => true, :value => retval}

		# ensure preview
		ensure_preview(@answer.is_preview)

		# ensure survey
		ensure_survey(@answer.survey_id)

		# ensure reward, use the reward info in answer
		ensure_reward(@answer.reward_scheme_id.to_s, @answer.rewards)

		# ensure spread url
		ensure_spread(@survey, @answer.reward_scheme_id)

		# load user bind info
		@binded = user_signed_in ? (current_user.email_activation || current_user.mobile_activation) : false
	end

	# AJAX
	def destroy_preview
		@answer = Answer.find_by_id(params[:id])
		render_json_e ErrorEnum::ANSWER_NOT_EXIST and return if @answer.nil?
		if @answer.is_preview
			# this is a preview answer, and the owner of the answer wants to clear the answer
			# delete answer id in cookies
			cookies.delete(cookie_key(@answer.survey._id.to_s, true), :domain => :all)
			# delete answer in db
			@answer.survey.answers.delete(@answer)
			retval = @answer.destroy
			render_json_auto(retval) and return 
		else
			render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return
		end
	end

	def clear
		@answer = Answer.find_by_id(params[:id])
		render_json_e ErrorEnum::ANSWER_NOT_EXIST and return if @answer.nil?
		render_json_auto @answer.clear and return
	end

	# AJAX
	def update
		@answer = Answer.find_by_id(params[:id])
		render_json_e ErrorEnum::ANSWER_NOT_EXIST and return if @answer.nil?

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

	# AJAX
	def load_questions
		@answer = Answer.find_by_id(params[:id])
		render_json_e ErrorEnum::ANSWER_NOT_EXIST and return if @answer.nil?
		render_json_e ErrorEnum::REQUIRE_LOGIN and return if @answer.user.present? && @answer.user != current_user
		@answer.update_status	# check whether it is time out
		if @answer.is_edit
			questions = @answer.load_question(params[:start_from_question], params[:load_next_page].to_s == "true")
			question_ids = questions.map { |e| e._id.to_s }
			if @answer.is_finish
				retval = {"answer_status" => @answer.status,
					"answer_reject_type" => @answer.reject_type,
					"answer_audit_message" => @answer.audit_message,
					"order_id" => @answer.order.try(:id),
					"order_status" => @answer.order.try(:status)}
				render_json_auto(retval) and return
			else
				answers = @answer.answer_content.merge(@answer.random_quality_control_answer_content)
				answers = answers.select { |k, v| question_ids.include?(k) }
				retval = {"answer_status" => @answer.status,
					"questions" => questions,
					"answers" => answers,
					"question_number" => @answer.survey.all_questions_id(false).length + @answer.random_quality_control_answer_content.length,
					"answer_index" => @answer.index_of(questions),
					"estimate_answer_time" => questions.estimate_answer_time,
					"repeat_time" => @answer.repeat_time,
					"order_id" => @answer.order.try(:_id),
					"order_status" => @answer.order.try(:status)}
				render_json_auto(retval) and return
			end
		else
			retval = {"answer_status" => @answer.status,
				"answer_reject_type" => @answer.reject_type,
				"answer_audit_message" => @answer.audit_message,
				"order_id" => @answer.order.try(:_id),
				"order_status" => @answer.order.try(:status)}
			render_json_auto(retval) and return
		end
	end

	# AJAX
	def finish
		@answer = Answer.find_by_id(params[:id])
		render_json_e ErrorEnum::ANSWER_NOT_EXIST and return if @answer.nil?
		render_json_auto @answer.finish and return
		# render :json => @ws_client.finish 
	end

	# AJAX
	def select_reward
		reward_index = -1
		mobile = nil
		alipay_account = nil
		answer = Answer.find_by_id(params[:id])
		render_json_e ErrorEnum::ANSWER_NOT_EXIST and return if answer.nil?
		answer.rewards.each_with_index do |r, i|
			case r['type']
			when 1
				if r['amount'] > 0 && params[:type] == 'chongzhi'
					reward_index = i
					mobile = params[:account]
					break
				end
			when 2
				if r['amount'] > 0 && params[:type] == 'zhifubao'
					reward_index = i
					alipay_account = params[:account]
					break
				end
			when 16
				if r['amount'] > 0 && params[:type] == 'jifenbao'
					reward_index = i
					alipay_account = params[:account]
					break
				end
			when 8
				if r['prizes'].length > 0
					reward_index = i
					break
				end
			end
		end
		retval = answer.select_reward(reward_index, mobile, alipay_account, current_user)
		render_json_auto retval and return
	end

	# AJAX
	def start_bind
		bind_ids = (cookies[Rails.application.config.bind_answer_id_cookie_key] || '').split('_')
		bind_ids << params[:id]
		bind_ids.uniq!
		cookies[Rails.application.config.bind_answer_id_cookie_key] = { 
			:value => bind_ids.join('_'), 
			:expires => Rails.application.config.answer_id_time_out_in_hours.hours.from_now ,
				:domain => :all
		}
		render_json_auto
		# render :json => Common::ResultInfo.ok
	end
end