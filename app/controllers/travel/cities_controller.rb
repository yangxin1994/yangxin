class Travel::CitiesController < Travel::TravelController
	before_filter :require_travel_sign_in
	before_filter :require_supervisor
	def index 
	end

	def show
	end
end