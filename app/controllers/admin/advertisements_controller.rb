# encoding: utf-8

# coding: utf-8

class Admin::AdvertisementsController < Admin::AdminController

	layout 'admin_new'
	
	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/advertisements")
	end

	# ****************************
	
	# GET
	def index
		hash_params={:page=> page, :per_page => per_page}
		hash_params.merge!({:activate => params[:activate].to_s == "true"}) if params[:activate]
		@advertisements = @client._get(hash_params)
		_sign_out and return if @advertisements.require_login?

		respond_to do |format|
			format.html
			format.json { render json: @advertisements}
		end
	end

	# GET
	def show
		@advertisement = @client._get({},"/#{params[:id]}")
		respond_to do |format|
			format.html
			format.json { render json: @advertisement}
		end
	end

	#
	def new
	end

	# POST
	def create
		photo = ImageUploader.new
		photo.store!(params[:image_location]) if params[:image_location]

		if photo.url.to_s.strip != ""
			@result = @client._post({
				:advertisement => {
						:title => params[:title],
						:linked => params[:linked],
						:image_location => photo.url.to_s,
						:activate => !params[:activate].to_s.blank?
					}
			})
		else
			@result = Common::ResultInfo.new({success: false, value: 'Image no exist.'})
		end

		if @result.success
			flash[:notice] ="创建成功!"
			# redirect_to :action => :index
		else
			flash[:notice] = "创建失败!请重新创建,并保证完整性和标题唯一性!"
			# render :action => :index
		end
		redirect_to :action => :index
	end

	# PUT
	def update
		photo = ImageUploader.new

		retval = @client._get({}, "/#{params[:id]}")
		photo.retrieve_from_store!(retval.value['image_location'].to_s.split('/').last) if retval.success
		
		if params[:image_location] 
			# del before
			# but not work!
			begin
				photo.remove!
			rescue Exception => e
				
			end
			# store new one
			photo.store!(params[:image_location])
		end

		if photo.url.to_s.strip != ""
			hash = {
						:title => params[:title],
						:linked => params[:linked],
						# protect the path
						:image_location => photo.url.to_s,
						:activate => !params[:activate].to_s.blank?
					}
			@advertisement = @client._put({
				:advertisement => hash
			}, "/#{params[:id]}")
		else
			@advertisement = Common::ResultInfo.new({success: false, value: 'Image no exist.'})
		end

		if @advertisement.success
			flash[:notice] ="更新成功!"
		else
			flash[:notice] = "更新失败!请重新更新,并保证完整性和标题唯一性!"
		end

		redirect_to request.url
	end

	# DELETE
	def destroy
		photo = ImageUploader.new
		retval = @client._get({}, "/#{params[:id]}")

		@result = @client._delete({}, "/#{params[:id]}")

		if @result.success
			photo.retrieve_from_store!(retval.value['image_location'].to_s.split('/').last)
			begin
				photo.remove!
			rescue Exception => e
				
			end
		end

		render :json => @result
	end

end