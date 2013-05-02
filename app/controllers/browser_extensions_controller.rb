# encoding: utf-8
require 'error_enum'
class BrowserExtensionsController < ApplicationController
	def show
		@be = BrowserExtension.find_by_type(params[:id])
		render :content_type => "application/xml" and return
	end
end
