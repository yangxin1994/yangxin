require 'error_enum'
class ShortUrlsController < ApplicationController
	
	def show
		retval = {"short_url" => MongoidShortener.generate(params[:id]) }
		render_json_auto retval and return
	end
end
