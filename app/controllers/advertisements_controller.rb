class AdvertisementsController < ApplicationController
	
	# GET /advertisements/1 
	# GET /advertisements/1.json
	def show
		@advertisement = Advertisement.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @advertisement }
		end
	end

end
