class Quill::AboutusController < ApplicationController

	layout 'quillhome'

	before_filter :activate_menu

	def activate_menu
		@activate_menu = 3
	end

	def show
	end
end