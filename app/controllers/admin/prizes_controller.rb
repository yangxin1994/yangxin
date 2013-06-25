class Admin::PrizesController < Admin::ApplicationController

	before_filter :check_prize_existence, :only => [:update, :destroy]

	def check_prize_existence
		@prize = Prize.find_by_id(params[:id])
		render_json_auto ErrorEnum::PRIZE_NOT_EXIST and return if @prize.nil?
	end

	def index
		render_json { auto_paginate(Prize.search_prize(params[:title], params[:type].to_i)) }
	end

	def create
		render_json Prize.create_prize(params[:prize]) and return
	end

	def update
		render_json_auto @prize.update_prize(params[:prize]) and return
	end

	def destroy
		render_json_auto @prize.delete_prize and return
	end
end