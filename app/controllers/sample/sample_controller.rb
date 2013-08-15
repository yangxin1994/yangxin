class Sample::SampleController < ApplicationController

	layout 'sample'

	def initialize(current_menu = 'home')
		@current_menu = current_menu
		super()
	end

	# def hide_right
	# 	@hide_right = true
	# end

end