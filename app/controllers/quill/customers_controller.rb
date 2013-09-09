class Quill::CustomersController < ApplicationController

	layout 'quillhome'

	before_filter :activate_menu

	def activate_menu
		@activate_menu = 2
	end

	def show
	end
	
end