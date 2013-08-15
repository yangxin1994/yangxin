class Filler::PreviewsController < Filler::FillerController

	# PAGE
	def show
		load_survey(params[:id], true)
	end

end