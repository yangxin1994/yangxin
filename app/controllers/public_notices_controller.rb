# coding: utf-8

class PublicNoticesController < ApplicationController
 
	# GET /public_notices
	# GET /public_notices.json
	def index
		@public_notices = PublicNotice.all.desc(:updated_at)
		if params[:public_notice_type]
			types = []
			PublicNotice::MAX_TYPE.downto(0).each { |element| 
				if params[:public_notice_type].to_i / (2**element) == 1 then
					types << 2**element
				end
			}
			@public_notices = @public_notices.where(:public_notice_type.in => types)
		end
		@public_notices = @public_notices.where(:title => Regexp.new(params[:title].to_s)) if params[:title]
		render_json_auto auto_paginate(@public_notices) and return
	end
	
	# GET /public_notices/1 
	# GET /public_notices/1.json
	def show
		@public_notice = PublicNotice.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @public_notice }
		end
	end

end