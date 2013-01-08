# coding: utf-8

class Admin::PublicNoticesController < Admin::ApplicationController	

	def maping(public_notice)
		user = User.find_by_id_including_deleted(public_notice['user_id'].to_s)
		public_notice['user_email'] = user.email if user
		public_notice
	end

	# GET /admin/public_notices
	# GET /admin/public_notices.json
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


		@show_public_notices = auto_paginate(@public_notices)
		# if not show content
		if params[:show_content].to_s=="false" 
			@show_public_notices['data'] = @show_public_notices['data'].map do |e|
				e['content'] = nil
			maping(e)
			end
		end

		render_json_auto @show_public_notices
	end
	
	# GET /admin/public_notices/1 
	# GET /admin/public_notices/1.json
	def show
		@public_notice = PublicNotice.find_by_id(params[:id])
		@public_notice = maping(@public_notice) if @public_notice.is_a? PublicNotice

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @public_notice }
		end
	end

	# GET /admin/public_notices/new
	# GET /admin/public_notices/new.json
	def new
		@public_notice = PublicNotice.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render_json_auto @public_notice }
		end
	end

	# GET /admin/public_notices/1/edit
	def edit
		@public_notice = PublicNotice.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @public_notice }
		end
	end
	
	# POST /admin/public_notices
	# POST /admin/public_notices.json
	def create
		@public_notice = PublicNotice.create_public_notice(params[:public_notice], @current_user)	
			
		respond_to do |format|
			format.html  if @public_notice.instance_of?(PublicNotice)
			format.html { render action: "new" } if !@public_notice.instance_of?(PublicNotice)
			format.json { render_json_auto @public_notice}
		end
	end

	# PUT /admin/public_notices/1
	# PUT /admin/public_notices/1.json
	def update
		@public_notice = PublicNotice.update_public_notice(params[:id], params[:public_notice], @current_user)

		respond_to do |format|
			format.html { redirect_to @public_notice} if @public_notice.instance_of?(PublicNotice)
			format.html { render action: "edit" } if !@public_notice.instance_of?(PublicNotice)
			format.json { render_json_auto @public_notice }
		end
	end

	# DELETE /admin/public_notices/1
	# DELETE /admin/public_notices/1.json
	def destroy
		@public_notice = PublicNotice.destroy_by_id(params[:id])

		respond_to do |format|
			format.html { redirect_to public_notices_url }
			format.json { render_json_auto @public_notice }
		end
	end
end
