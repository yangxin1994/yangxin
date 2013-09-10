class Quill::IndicesController < ApplicationController

	layout 'quillhome'

	def show
		if Rails.env.production? && request.host != request.domain
			redirect_to "#{request.protocol}#{request.domain}"
		end
	end
	
end