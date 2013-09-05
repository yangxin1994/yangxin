class AdvertisementsController < ApplicationController

	# GET /advertisements
	# GET /advertisements.json
	def index
		@advertisements = Advertisement.all 
		if params[:advertisement_type]
			types = []
			Advertisement::MAX_TYPE.downto(0).each { |element| 
				if params[:advertisement_type].to_i / (2**element) == 1 then
					types << 2**element
				end
			}
			@advertisements = @advertisements.where(:advertisement_type.in => types)
		end
		@advertisements = @advertisements.where(:title => Regexp.new(params[:title].to_s)) if params[:title]
		@advertisements =  @advertisements.where(:activate => params[:activate].to_s == 'true') if params[:activate]
			
		render_json_auto auto_paginate(@advertisements.desc(:created_at))
	end
	
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
