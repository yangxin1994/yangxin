# encoding: utf-8
class Admin::AwardsController < Admin::ApplicationController

	def create		
		respond_to do |format|
			@award = Award.create(params[:award])
			# TO DO add admin_id
			if @award.save
				Material.create(:material => params[:material], :materials => @award)
				format.html { redirect_to :action => 'show',:id => @award.id }
				format.json { render json: @award, status: :created, location: @award }
			else
				#format.html { render action: "cash" }
				format.json { render json: false }
			end
		end
	end
	
	def stockout
		@awards = Award.stockout.page(page)
		respond_to do |format|
			format.html 
			format.json { render json: @awards, :only => [:id, :name, :point, :quantity, :created_at, :status] }
		end
	end

	def update
		@award = Award.find(params[:id])

		respond_to do |format|
			if @award.update_attributes(params[:award])
				format.html { redirect_to @award, notice: 'Award was successfully updated.' }
				format.json { head :ok }
			else
				#format.html { render action: "edit" }
				format.json { render json: @award.errors, status: :unprocessable_entity }
			end
		end
	end

	def delete
		@awards = []
		params[:ids].to_a.each do |id|
			@awards << (Award.find_by_id id do |r|
				r.delete
			end)
		end
		respond_to do |format|
			format.json { render json: @awards }
		end
	end


end