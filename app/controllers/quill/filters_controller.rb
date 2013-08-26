# finish migrating
class Quill::FiltersController < Quill::QuillController
	
	before_filter :ensure_survey

	def initialize
		super(4)
	end
	
	# PAGE: index survey filters
	def index
		@survey_questions = get_survey_questions
	end

	# PAGE: show survey filter
	def show
		@survey_questions = get_survey_questions

		filters = @survey.filters || []
		@current_index = -1
		@current_filter = nil
		index = params[:id].to_s
		if index.to_i.to_s == index
			index = index.to_i
			if index >= 0 && index < filters.length
				@current_index = index
				@current_filter = filters[index]
			end
		end
	end

	# AJAX: destory a filter by its index
	def destroy
		retval = @survey.delete_filter(params[:id].to_i)
		render_json_auto retval and return
	end

	# AJAX: update filter by its index
	def update
		retval = @survey.update_filter(params[:id].to_i, params[:filter])
		render_json_auto retval and return
	end

	# AJAX: create a new filter
	def create
		retval = @survey.add_filter(params[:filter])
		render_json_auto retval and return
	end
end