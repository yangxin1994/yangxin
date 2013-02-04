class WelcomeController < ApplicationController

	def index
		render :text => params.inspect and return
		if user_signed_in?
			redirect_to home_path and return
		end
	end

end
