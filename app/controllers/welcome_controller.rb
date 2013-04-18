class WelcomeController < ApplicationController
	def index
		AnalysisWorker.perform_async("", "", "", "")
		render :text => "quite well done!!!"
	end
end
