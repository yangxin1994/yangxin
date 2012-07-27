# encoding: utf-8
class Admin::PresentsController < Admin::ApplicationController

	def create		
		respond_to do |format|
			@present = Present.create(params[:present])
			# TO DO add admin_id
			if @present.save
				Material.create(:material => params[:material], :materials => @present)
				format.html { redirect_to :action => 'show',:id => @present.id }
				format.json { render json: @present, status: :created, location: @present }
			else
				#format.html { render action: "cash" }
				format.json { render json: false }
			end
		end
	end
	
	def expired
		@presents = Present.expired.page(page)
		respond_to do |format|
			format.html 
			format.json { render json: @presents, :only => [:id, :name, :point, :quantity, :created_at, :status] }
		end
	end

	def update
		@present = Present.find(params[:id])

		respond_to do |format|
			if @present.update_attributes(params[:present])
				format.html { redirect_to @present, notice: 'Present was successfully updated.' }
				format.json { head :ok }
			else
				#format.html { render action: "edit" }
				format.json { render json: @present.errors, status: :unprocessable_entity }
			end
		end
	end

	def delete
		@presents = []
		params[:ids].to_a.each do |id|
			@presents << (Present.find_by_id id do |r|
				r.delete
			end)
		end
		respond_to do |format|
			format.json { render json: @presents }
		end
	end


end