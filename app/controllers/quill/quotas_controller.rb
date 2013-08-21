# finish migrating
class Quill::QuotasController < Quill::QuillController
	before_filter :ensure_survey
	
	# AJAX: destory a quota by its index
	def destroy
		retval = @survey.delete_quota_rule(params[:id].to_i)
		render_json_auto retval and return
	end

	# AJAX: update s quota by its index
	def update
		retval = @survey.update_quota_rule(params[:id].to_i, params[:quota])
		render_json_auto retval and return
	end

	# AJAX: create a new quota
	def create
		retval = @survey.add_quota_rule(params[:quota])
		render_json_auto retval and return
	end

	# AJAX: refresh quotas stat
	def refresh
		retval = @survey.refresh_quota_stats
		render_json_auto retval and return
	end
end