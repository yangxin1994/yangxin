class ResultsController < ApplicationController
	before_filter :require_sign_in, :check_survey_existence

=begin
	def set_filter
		answers = @survey.answers.not_preview.finished
		if params[:filter_index].blank?
			@answers = answers
			return
		end
		filter = @survey.filters[params[:filter_index].to_i]
		@answers = []
		answers.each do |a|
			@answers << a if a.satisfy_conditions(filter["conditions"])
		end
	end
=end

	def check_survey_existence
		@survey = @current_user.surveys.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def show
		result = @survey.show_result(params[:filter_name])
		respond_to do |format|
			format.json	{ render_json_auto(result) and return }
		end

	end

	def refresh
		result = @survey.refresh_result(params[:filter_name])
		respond_to do |format|
			format.json	{ render_json_auto(result) and return }
		end
	end
end
