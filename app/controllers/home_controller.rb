class HomeController < ApplicationController

	# method: get
	# description: the home page of an user
  def index
		if user_signed_out?
			redirect_to root_path and return
		end

  end

end
