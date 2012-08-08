# coding: utf-8

class Admin::PublicNoticesController < Admin::ApplicationController	
 
	# GET /admin/public_notices
	# GET /admin/public_notices.json
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
	
	# GET /admin/public_notices/1 
	# GET /admin/public_notices/1.json
	def show
		@public_notice = PublicNotice.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @public_notice }
		end
	end

	# GET /admin/public_notices/new
	# GET /admin/public_notices/new.json
	def new
		@public_notice = PublicNotice.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @public_notice }
		end
	end

	# GET /admin/public_notices/1/edit
	def edit
		@public_notice = PublicNotice.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @public_notice }
		end
	end
	
	# POST /admin/public_notices
	# POST /admin/public_notices.json
	def create
		@public_notice = PublicNotice.create_public_notice(params[:public_notice], @current_user)	
			
		respond_to do |format|
			format.html  if @public_notice.instance_of?(PublicNotice)
			format.html { render action: "new" } if !@public_notice.instance_of?(PublicNotice)
			format.json { render :json => @public_notice}
		end
	end

	# PUT /admin/public_notices/1
	# PUT /admin/public_notices/1.json
	def update
		@public_notice = PublicNotice.update_public_notice(params[:id], params[:public_notice], @current_user)

		respond_to do |format|
			format.html { redirect_to @public_notice} if @public_notice.instance_of?(PublicNotice)
			format.html { render action: "edit" } if !@public_notice.instance_of?(PublicNotice)
			format.json { render :json => @public_notice }
		end
	end

	# DELETE /admin/public_notices/1
	# DELETE /admin/public_notices/1.json
	def destroy
		@public_notice = PublicNotice.destroy_by_id(params[:id])

		respond_to do |format|
			format.html { redirect_to public_notices_url }
			format.json { render :json => @public_notice }
		end
	end
end
