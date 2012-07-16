class AdvertisementsController < ApplicationController
	
	before_filter :require_admin,  :except => [:show]

	# GET /advertisements
	# GET /advertisements.json
	def index
		if params[:activate] && params[:activate] =="true" then
			@advertisements = Advertisement.activated
		elsif params[:activate] && params[:activate]=="false" then
			@advertisements = Advertisement.unactivate
		else
			@advertisements = Advertisement.all.desc(:updated_at)
		end

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @advertisements }
		end
	rescue 
		respond_to do |format|
			format.html
			format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
		end
	end

	# GET /advertisements/1
	# GET /advertisements/1.json
	def show
		@advertisement = Advertisement.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @advertisement }
		end
	rescue 
		respond_to do |format|
			format.html
			format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
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
	rescue 
		respond_to do |format|
			format.html
			format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
		end
	end

	# GET /advertisements/1/edit
	def edit
		@advertisement = Advertisement.find(params[:id])
	end

	# POST /advertisements
	# POST /advertisements.json
	def create
		@advertisement = Advertisement.new(params[:advertisement])

		respond_to do |format|
			if @advertisement.save(current_user)
				format.html { redirect_to @advertisement, notice: 'Advertisement was successfully created.' }
				format.json { render json: @advertisement, status: :created, location: @advertisement }
			else
				format.html { render action: "new" }
				format.json { render json: @advertisement.errors, status: :unprocessable_entity }
			end
		end
	rescue 
		respond_to do |format|
			format.html { render action: "new" }
			format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
		end
	end

	# PUT /advertisements/1
	# PUT /advertisements/1.json
	def update
		@advertisement = Advertisement.find(params[:id])

		respond_to do |format|
			if @advertisement.update_attributes(params[:advertisement], current_user)
				format.html { redirect_to @advertisement, notice: 'Advertisement was successfully updated.' }
				format.json { render :json => @advertisement }
			else
				format.html { render action: "edit" }
				format.json { render :json => ErrorEnum::SAVE_FAILED }
			end
		end
	rescue 
		respond_to do |format|
			format.html { render action: "edit" }
			format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
		end
	end

	# DELETE /advertisements/1
	# DELETE /advertisements/1.json
	def destroy
		@advertisement = Advertisement.find(params[:id])
		@advertisement.destroy

		respond_to do |format|
			format.html { redirect_to advertisements_url }
			format.json { render :json => true }
		end
	rescue 
		respond_to do |format|
			format.html
			format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
		end
	end
end
