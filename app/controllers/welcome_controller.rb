class WelcomeController < ApplicationController

	def index

		path = 'public/data'
		File.open(path, "wb") { |f| f.write(params[:file].read) }

		render :text => params.inspect and return
		if user_signed_in?
			redirect_to home_path and return
		end
	end

	def upload
		
	end

end
