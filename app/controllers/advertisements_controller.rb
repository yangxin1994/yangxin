class AdvertisementsController < ApplicationController
	
	before_filter :require_admin,  :except => [:show]

	# GET /advertisements
	# GET /advertisements.json
	def index
		if !params[:activate].nil? then
			if params[:activate].to_s == "true" then
				@advertisements = Advertisement.activated
			elsif params[:activate].to_s == "false" then
				@advertisements = Advertisement.unactivate
			end
			@advertisements.desc(:updated_at) if @advertisements && @advertisements.count > 1
		elsif !params[:title].nil? then
			@advertisements = Advertisement.list_by_title(params[:title])
		else
			@advertisements = Advertisement.all.desc(:updated_at)
		end

		@advertisements =  slice((@advertisements || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @advertisements }
		end
	end
	
	# GET /advertisements/1 
	# GET /advertisements/1.json
	def show
		@advertisement = Advertisement.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @advertisement, :except => "user_id" }
		end
	end

	# GET /advertisements/new
	# GET /advertisements/new.json
	def new
		@advertisement = Advertisement.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @advertisement }
		end
	end

	# GET /advertisements/1/edit
	def edit
		@advertisement = Advertisement.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @system_user }
		end
	end
	
	# POST /advertisements
	# POST /advertisements.json
	def create
		@advertisement = Advertisement.create_advertisement(params[:advertisement], @current_user)	
			
		respond_to do |format|
			format.html  if @advertisement.instance_of?(Advertisement)
			format.html { render action: "new" } if !@advertisement.instance_of?(Advertisement)
			format.json { render :json => @advertisement}
		end
	end

	# PUT /advertisements/1
	# PUT /advertisements/1.json
	def update
		@advertisement = Advertisement.update_advertisement(params[:id], params[:advertisement], @current_user)

		respond_to do |format|
			format.html { redirect_to @advertisement} if @advertisement.instance_of?(Advertisement)
			format.html { render action: "edit" } if !@advertisement.instance_of?(Advertisement)
			format.json { render :json => @advertisement }
		end
	end

	# DELETE /advertisements/1
	# DELETE /advertisements/1.json
	def destroy
		@advertisement = Advertisement.destroy_by_id(params[:id])

		respond_to do |format|
			format.html { redirect_to advertisements_url }
			format.json { render :json => @advertisement }
		end
	end

end
