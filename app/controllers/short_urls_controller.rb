require 'error_enum'
class ShortUrlsController < ApplicationController
	
	def create
		retval = MongoidShortener.generate(params[:link])
		render_json_auto retval and return
	end

	def show
		retval = MongoidShortener.translate(params[:id])
		render_json_auto retval and return
	end
end
