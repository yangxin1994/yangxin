# encoding: utf-8
class Admin::AwardsController < Admin::ApplicationController

	def create
		@award = Award.create(params[:award])
		Material.create(:material => params[:material], :materials => @award)
		respond_and_render_json @award.save do
			@award.as_retval
		end
	end
	
	def stockout
		respond_and_render_json { @awards }
	end

	def update
		@award = Award.find(params[:id])
		respond_and_render_json @award.update_attributes(params[:award]) do
			@award.as_retval
		end
	end

	def delete
		params[:ids] ||= []
		respond_and_render_json do
			params[:ids].to_a.each do |id|
				Award.find_by_id id do |r|
					r.delete
				end
			end
		end
		# @awards = []
		# params[:ids].to_a.each do |id|
		# 	@awards << (Award.find_by_id id do |r|
		# 		r.delete
		# 	end)
		# end
		# respond_to do |format|
		# 	format.json { render json: @awards }
		# end
	end


end