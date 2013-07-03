class Agent::SurveysController < Agent::ApplicationController

	def index
		@surveys = Survey.normal.published.map { |e| e.info_for_agent }
		render_json_auto @surveys and return
	end
end