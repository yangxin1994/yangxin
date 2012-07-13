# coding: utf-8

class PublicNoticesController < ApplicationController

	before_filter :require_admin, :except=>[:index, :show, :condition, :types]

	# GET /public_notices
	# GET /public_notices.json
	def index
		@public_notices = PublicNotice.all.desc(:updated_at)

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @public_notices }
		end
	end

	# GET /public_notices/1
	# GET /public_notices/1.json
	def show
		@public_notice = PublicNotice.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @public_notice }
		end
	end

	# GET /public_notices/new
	# GET /public_notices/new.json
	def new
		@public_notice = PublicNotice.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @public_notice }
		end
	end

	# GET /public_notices/1/edit
	def edit
		@public_notice = PublicNotice.find(params[:id])
	end

	# POST /public_notices
	# POST /public_notices.json
	def create
		@public_notice = PublicNotice.new(params[:public_notice])

		respond_to do |format|
			if @public_notice.save(current_user)
				format.html { redirect_to @public_notice, notice: "添加成功。" }
				format.json { render json: @public_notice, status: :created, location: @public_notice }
			else
				format.html { render action: "new" }
				format.json { render :json => ErrorEnum::SAVE_FAILED}
			end
		end
	rescue => ex
		if ex.class == TypeError then
			respond_to do |format|
				format.html { render action: "new"}
				format.json { render :json => ErrorEnum::TYPE_ERROR}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html { render action: "new" }
				format.json { render :json => ErrorEnum::RANGE_ERROR}
			end
		else
			respond_to do |format|
				format.html { render action: "new" }
				format.json { render :json => ErrorEnum::SAVE_FAILED}
			end
		end
	end

	# PUT /public_notices/1
	# PUT /public_notices/1.json
	def update
		@public_notice = PublicNotice.find(params[:id])

		respond_to do |format|
			if @public_notice.update_attributes(params[:public_notice], current_user)
				format.html { redirect_to @public_notice, notice: "更新成功。" }
				format.json { render :json => @public_notice }
			else
				format.html { render action: "edit" }
				format.json { render :json => ErrorEnum::SAVE_FAILED}
			end
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html { render action: "edit"}
				format.json { render :json => ErrorEnum::TYPE_ERROR}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html { render action: "edit" }
				format.json { render :json => ErrorEnum::RANGE_ERROR}
			end
		else
			respond_to do |format|
				format.html { render action: "edit" }
				format.json { render :json => ErrorEnum::SAVE_FAILED}
			end
		end
	end

	# DELETE /public_notices/1
	# DELETE /public_notices/1.json
	def destroy
		@public_notice = PublicNotice.find(params[:id])
		@public_notice.destroy

		respond_to do |format|
			format.html { redirect_to public_notices_url }
			format.json { render :json => true }
		end
	end
	
	# GET /public_notices/condition
	# GET /public_notices/condition.json
	def condition
		type = params[:type] || 0
		value = params[:value] || ""

		@public_notices = PublicNotice.condition(type, value)
		
		respond_to do |format|
			format.html
			format.json { render json: @public_notices }
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::TYPE_ERROR}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::RANGE_ERROR}
			end
		elsif ex.class == ArgumentError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::ARG_ERROR}
			end
		else
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
			end
		end
	end

	# GET /public_notices/types
	# GET /public_notices/types.json
	def types
		type = params[:type] || 0
		@public_notices = PublicNotice.find_by_type(type)
		
		respond_to do |format|
			format.html
			format.json { render json: @public_notices }
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::TYPE_ERROR}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::RANGE_ERROR}
			end
		elsif ex.class == ArgumentError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::ARG_ERROR}
			end
		else
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
			end
		end
	end
end
