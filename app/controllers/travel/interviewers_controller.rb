class Travel::InterviewersController < Travel::TravelController
	before_filter :require_travel_sign_in
	def show
	end
end