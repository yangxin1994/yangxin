require 'error_enum'
class ShortUrlsController < ApplicationController
	
	def show
		logger.info "AAAAAAAAA"
		logger.info params[:id]
		logger.info "AAAAAAAAA"
		retval = {"short_url" => MongoidShortener.generate(params[:id]) }
		logger.info "BBBBBBBBB"
		logger.info MongoidShortener.generate(params[:id])
		logger.info "BBBBBBBBB"
		render_json_auto retval and return
	end
end
