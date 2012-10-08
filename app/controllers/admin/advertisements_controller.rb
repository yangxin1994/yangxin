class Admin::AdvertisementsController < Admin::ApplicationController

	# GET /admin/advertisements
	# GET /admin/advertisements.json
	def index
		if !params[:activate].nil? then
			if params[:activate].to_s == "true" then
				@advertisements = Advertisement.activated.desc(:updated_at).page(page).per(per_page)
			elsif params[:activate].to_s == "false" then
				@advertisements = Advertisement.unactivate.desc(:updated_at).page(page).per(per_page)
			end
		elsif !params[:title].nil? then
			@advertisements = Advertisement.list_by_title(params[:title])
			# @@search_count = @advertisements.count
			# @advertisements =  slice((@advertisements || []), page, per_page)
		else
			@advertisements = Advertisement.all.desc(:updated_at).page(page).per(per_page)
		end		

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @advertisements }
		end
	end

	# GET
	def count
		render_json_auto Advertisement.count
	end

	#GET
	def activated_count
		render_json_auto Advertisement.activated.count
	end

	#GET
	def unactivate_acount
		render_json_auto Advertisement.unactivate.count
	end
	
	# GET /admin/advertisements/1 
	# GET /admin/advertisements/1.json
	def show
		@advertisement = Advertisement.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @advertisement }
		end
	end

	# GET /admin/advertisements/new
	# GET /admin/advertisements/new.json
	def new
		@advertisement = Advertisement.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @advertisement }
		end
	end

	# GET /admin/advertisements/1/edit
	def edit
		@advertisement = Advertisement.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @advertisement }
		end
	end
	
	# POST /admin/advertisements
	# POST /admin/advertisements.json
	def create
		@advertisement = Advertisement.create_advertisement(params[:advertisement], @current_user)	
			
		respond_to do |format|
			format.html  if @advertisement.instance_of?(Advertisement)
			format.html { render action: "new" } if !@advertisement.instance_of?(Advertisement)
			format.json { render :json => @advertisement}
		end
	end

	# PUT /admin/advertisements/1
	# PUT /admin/advertisements/1.json
	def update
		@advertisement = Advertisement.update_advertisement(params[:id], params[:advertisement], @current_user)

		respond_to do |format|
			format.html { redirect_to @advertisement} if @advertisement.instance_of?(Advertisement)
			format.html { render action: "edit" } if !@advertisement.instance_of?(Advertisement)
			format.json { render :json => @advertisement }
		end
	end

	# DELETE /admin/advertisements/1
	# DELETE /admin/advertisements/1.json
	def destroy
		@advertisement = Advertisement.destroy_by_id(params[:id])

		respond_to do |format|
			format.html { redirect_to advertisements_url }
			format.json { render :json => @advertisement }
		end
	end

end
