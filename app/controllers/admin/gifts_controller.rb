class Admin::GiftsController < Admin::ApplicationController

	before_filter :check_gift_existence, :only => [:show, :update, :destroy]

	def check_gift_existence
		@gift = Gift.find_by_id(params[:id])
		render_json_auto(ErrorEnum::GIFT_NOT_EXIST) and return if @gift.nil?
	end

	def index
		@gifts = Gift.search_gift(params[:title], params[:status].to_i, params[:type].to_i)
		render_json_auto(auto_paginate(@gifts)) and return
	end

	def show
		@gift['photo_url'] = @gift.photo.try 'value'
		render_json_auto(@gift)
	end

	def create
		@gift = Gift.create_gift(params[:gift])
		render_json_auto(@gift) and return
	end

	def update
		render_json_auto(@gift.update_gift(params[:gift])) and return
	end

	def destroy
		render_json_auto(@gift.delete_gift) and return
	end
end
