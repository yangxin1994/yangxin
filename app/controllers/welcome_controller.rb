class WelcomeController < ApplicationController
	def index
		AnalysisWorker.perform_async("", "", "", "")
		render :text => "well done"
	end
end
