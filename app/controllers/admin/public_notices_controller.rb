# coding: utf-8

class Admin::PublicNoticesController < Admin::ApplicationController	

	def maping(public_notice)
		public_notice['user_email'] = User.find(public_notice['user_id'].to_s).email
		public_notice
	end

	# GET /admin/public_notices
	# GET /admin/public_notices.json
	def index
		if !params[:public_notice_type].nil? then
			if !params[:value].nil? then
				@public_notices = PublicNotice.list_by_type_and_value(params[:public_notice_type], params[:value])
			else
				@public_notices = PublicNotice.list_by_type(params[:public_notice_type]) 
			end

			@public_notices = slice((@public_notices || []), page, per_page)
		else
			@public_notices = PublicNotice.all.desc(:updated_at).page(page).per(per_page)
		end

		# if not show content
		tmp = params[:show_content].to_s=="false" ? true : false
		@public_notices = @public_notices.map do |e|
			e.content = nil if tmp
			maping(e)
		end

		render_json_auto @public_notices
	end

	def count
		count = PublicNotice.count
		render_json_auto count
	end

	def list_by_type_count
		@public_notices = PublicNotice.list_by_type(params[:public_notice_type]) 
		render_json_auto @public_notices.count
	end

	def list_by_type_and_value_count
		@public_notices = PublicNotice.list_by_type_and_value(params[:public_notice_type], params[:value])
		render_json_auto @public_notices.count
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
