class Admin::BrowsersController < Admin::ApplicationController
	before_filter :require_sign_in

	def role
		render_json_s(@current_user.role) and return
	end
 
	def tasks
		answer_audit = @current_user.is_admin? || @current_user.is_answer_auditor?
		handle_order = @current_user.is_admin?

		answers_wait_for_audit = []
		orders_wait_for_handle = []

		if answer_audit
			Answer.unreviewed.each do |a|
				answers_wait_for_audit << {"survey_title" => a.survey.title,
					"answer_id" => a._id.to_s,
					"link" => "/admin/review_answers/#{a.survey._id.to_s}/answers/#{a._id.to_s}"}
			end
		end

		if handle_order
			Order.need_verify.each do |o|
				orders_wait_for_handle << {"present_name" => o.gift.name,
					"order_id" => o._id.to_s,
					"link" => "/admin/orders?scope=need_verify"}
			end
		end

		be = BrowserExtension.where(:browser_extension_type => "chrome_admin").first
		version = be.try(:version)

		render_json_s({ "answer_audit" => answers_wait_for_audit,
			"order" => orders_wait_for_handle,
			"version" => version })
	end	
end
