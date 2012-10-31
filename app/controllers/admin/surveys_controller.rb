class Admin::SurveysController < Admin::ApplicationController

	def index
		@surveys = Survey.all.page(page).per(per_page)
		render_json_auto(@surveys)
	end

	def count
		render_json_auto Survey.count
	end

	def list_by_status
		@surveys = Survey.all.page(page).per(per_page)
		render_json_auto(@surveys)
	end

	def list_by_status_count
		@surveys = Survey.all.page(page).per(per_page)
		render_json_auto(@surveys)
	end

end