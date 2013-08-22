# coding: utf-8

class Admin::PublicNoticesController < Admin::ApplicationController	

	def maping(public_notice)
		user = User.find_by_id_including_deleted(public_notice['user_id'].to_s)
		public_notice['user_email'] = user.email if user
		public_notice
	end

	def index
		render_json auto_paginate(PublicNotice.find_valid_notice.find_by_title(params[:title])) 
	end
	
	def show
		@public_notice = PublicNotice.find_by_id(params[:id])
		render_json_auto ErrorEnum::PUBLIC_NOTICE_NOT_EXIST and return if @public_notice.blank?
		@public_notice = maping(@public_notice)
		render_json_auto @public_notice and return
	end

	def create
		@public_notice = PublicNotice.create_public_notice(params[:public_notice], @current_user)
		render_json_auto @public_notice and return
	end

	def update
		@public_notice = PublicNotice.update_public_notice(params[:id], params[:public_notice], @current_user)
		render_json_auto @public_notice and return
	end

	def destroy
		@public_notice = PublicNotice.destroy_by_id(params[:id])
	    render_json_auto @public_notice and return
	end
end
