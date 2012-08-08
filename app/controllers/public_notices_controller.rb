# coding: utf-8

class PublicNoticesController < ApplicationController
 
	# GET /public_notices
	# GET /public_notices.json
	def index
		if !params[:public_notice_type].nil? then
			if !params[:value].nil? then
				@public_notices = PublicNotice.list_by_type_and_value(params[:public_notice_type], params[:value])
			else
				@public_notices = PublicNotice.list_by_type(params[:public_notice_type]) 
			end
		else
			@public_notices = PublicNotice.all.desc(:updated_at)
		end

		@public_notices = slice((@public_notices || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @public_notices }
		end
	end
	
	# GET /public_notices/1 
	# GET /public_notices/1.json
	def show
		@public_notice = PublicNotice.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @public_notice }
		end
	end

end