class PresentsController < ApplicationController
	#TO DO before_filter
	# presents.json?page=1

	#*method*: get
	#
	#*url*: /presents
	#
	#*description*: list all presents can be rewarded
	#
	#*params*:
	#* page: page number
	#
	#*retval*:
	#* the Survey object: when meta data is successfully saved.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user

	def index
		@presents = Present.can_be_rewarded.page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @presents, :only => [:id, :name, :point, :quantity, :created_at, :status] }
		end
	end

	def expired
		@presents = Present.expired.page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @presents, :only => [:id, :name, :point, :quantity, :created_at, :status] }
		end
	end
	def_each :virtual_goods, :cash, :real_goods, :stockout do |method_name|
		flash[:notice] = "No Goods" unless @presents = Present.send(method_name).can_be_rewarded.page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @presents, :only => [:id, :name, :point, :quantity, :created_at, :status]  }
		end
	end
	def new
		@present = Present.new

		respond_to do |format|
			format.html 
			format.json { render json: @present }
		end		
	end
	def create		
		respond_to do |format|
			if @present = Present.create(params[:present])
				Material.create(:material => params[:material], :materials => @present)
				format.html { redirect_to :action => 'show',:id => @present.id }
				format.json { render json: @present, status: :created, location: @present }
			else
				format.html { render action: "new" }
				format.json { render json: @present.errors, status: :unprocessable_entity }
			end
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

	def delete_tag
		#params[:ids]  
	end

	def destroy
		#TO DO 
		#params[:ids]

		@present = Present.find(params[:id])
		@present.destroy

		respond_to do |format|
			#format.html { redirect_to presents_url }
			format.json { head :ok }
		end
	end

	def show
		@present = Present.find(params[:id])
		respond_to do |format|
			format.json { render json: @present}
		end
	end
end
