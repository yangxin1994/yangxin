class WelcomeController < ApplicationController
	def index
		AnalysisWorker.perform_async("", "", "", "")
		render :text => "done"
	end
end
