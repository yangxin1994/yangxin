# finish migrating
class Filler::BindSamplesController < Filler::FillerController

	before_filter :require_sign_in

	# PAGE
	def show
		bind_ids = (cookies[Rails.application.config.bind_answer_id_cookie_key] || '').split('_')
		redirect_to_answer_id = nil
		bind_ids.each do |aid|
			answer = Answer.find_by_id(aid)
			next if answer.nil?
			# client = Sample::AnswerClient.new(session_info, aid)
			# answer = client.show
			# if answer.success
			# 	answer = answer.value
			# bind answer to the current user
			next if answer.user.present?
			answer.bind_sample(@current_user)

			redirect_to_answer_id = aid 
			# delete filler id
			if cookies["#{answer['survey_id']}_0"] == aid
				cookies.delete("#{answer['survey_id']}_0", :domain => :all)
			end
			# delete preview id
			if cookies["#{answer['survey_id']}_1"] == aid
				cookies.delete("#{answer['survey_id']}_1", :domain => :all)
			end
		end
		# delete answer ids in cookie
		cookies.delete(Rails.application.config.bind_answer_id_cookie_key, :domain => :all)

		if params[:ref].present?
			redirect_to params[:ref]
		elsif !redirect_to_answer_id.nil?
			redirect_to show_a_path(redirect_to_answer_id)
		else
			redirect_to root_path
		end
	end
end