class Filler::SurveysController < Filler::FillerController

	# PAGE
	def show
		load_survey(params[:id])
	end
end