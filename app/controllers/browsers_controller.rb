require 'error_enum'
class BrowsersController < ApplicationController
	before_filter :check_extension_version

	def check_extension_version
		@be = BrowserExtension.find_by_type(params[:browser_extension_type])
		render_json_e(ErrorEnum::BROWSER_EXTENSION_NOT_EXIST) and return if @be.nil?
	end

	def create
		browser = Browser.create
		browser.browser_extension = @be
		browser.save
		render_json_s(browser._id.to_s) and return
	end

	def update_history
		# get the browser instance
		@browser = Browser.find_by_id(params[:id])
		render_json_e(ErrorEnum::BROWSER_NOT_EXIST) and return if @browser.nil?
		@browser.update_attribute(:last_request_time => Time.now.to_i)

		# update the history
		render_json_s and return
	end

end
