require 'error_enum'
class ShortUrlsController < ApplicationController
	
	def create
		retval = {"short_url" => MongoidShortener.generate(params[:link]) }
		render_json_auto retval and return
	end
end
