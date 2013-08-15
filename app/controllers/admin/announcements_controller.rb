# encoding: utf-8

# coding: utf-8

class Admin::AnnouncementsController < Admin::AdminController

	layout 'layouts/admin-todc'
	
	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/public_notices")
	end
	
	# GET
	def index
		hash_params={:page=> page, :per_page => per_page, :show_content => false}
		hash_params.merge!({:public_notice_type => params[:type].to_i}) if params[:type]
		hash_params.merge!({:title => params[:title]}) if params[:title]

		result = @client._get(hash_params)
		if result.success
			@announcements = result.value
		else
			render :json => result
		end
	end

	# GET
	def show
		@announcement = @client._get({},"/#{params[:id]}")
		respond_to do |format|
			format.html
			format.json { render json: @announcement}
		end

	end

	# POST
	def create
		params[:type] = params[:type].to_i
		
		photo = ImageUploader.new

		photo.store!(params[:attachment]) if params[:attachment]

		if photo.url.to_s.strip != ""
			@result = @client._post({
				:public_notice => {
					:public_notice_type => params[:type].to_i,
					:title =>  params[:title],
					:content =>  params[:content],
					:attachment => photo.url.to_s
				}
			})
		else
			@result = @client._post({
				:public_notice => {
					:public_notice_type => params[:type].to_i,
					:title =>  params[:title],
					:content =>  params[:content]
				}
			})
		end
		if @result.success
			flash[:notice] = "创建成功!"
		else
			flash[:notice] = "创建失败!请重新创建,并保证完整性和标题唯一性!"
		end
		redirect_to :action => :index
		# render :json => @result
	end

	# PUT
	def update
		
		photo = ImageUploader.new

		retval = @client._get({}, "/#{params[:id]}")
		photo.retrieve_from_store!(retval.value['attachment'].to_s.split('/').last)
		
		if params[:attachment]
			# del before
			# but not work!
			begin
				photo.remove!
			rescue Exception => e
				
			end
			# store new one
			photo.store!(params[:attachment])
		end

		if photo.url.to_s.strip != ""
			@result = @client._put({
				:public_notice => {
					:public_notice_type => params[:type].to_i,
					:title =>  params[:title],
					:content =>  params[:content],
					:attachment => photo.url.to_s
				}
			}, "/#{params[:id]}")
		else
			@result = @client._put({
				:public_notice => {
					:public_notice_type => params[:type].to_i,
					:title =>  params[:title],
					:content =>  params[:content]
				}
			}, "/#{params[:id]}")
		end

		if @result.success
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
			photo.retrieve_from_store!(retval.value['attachment'].to_s.split('/').last)
			begin
				photo.remove!
			rescue Exception => e
				
			end
		end

		render :json => @result
	end

end