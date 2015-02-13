# encoding: utf-8
class Travel::UsersController < Travel::TravelController
	layout false
	def login
		redirect_to travel_path if current_user && current_user.is_supervisor?
	end
end