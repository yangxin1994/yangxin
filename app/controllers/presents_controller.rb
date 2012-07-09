class PresentsController < ApplicationController
	#TO DO before_filter
	# presents.json?page=1
	def index
		@presents = Present.page(params[:page].to_i)
		respond_to do |format|
			format.json { render json: @presents, :only => [:name, :point] }
		end
	end

	def_each :virtual_goods, :cash, :real_goods do |method_name|
		flash[:notice] = "No Goods" unless @presents = Present.send((method_name.to_s + "_present").to_sym).can_be_rewarded.page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @presents }
		end
	end
	def new
    @present = Present.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @present }
    end		
	end
	def create		
    respond_to do |format|
      if @present = Present.create(params[:present])
        format.html { redirect_to :action => 'show',:id => @present.id }
        #format.json { render json: @present, status: :created, location: @present }
      else
        format.html { render action: "new" }
        #format.json { render json: @present.errors, status: :unprocessable_entity }
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

  def destroy
  	#TO DO 
  	#params[:ids]
    @present = Present.find(params[:id])
    @present.destroy

    respond_to do |format|
      #format.html { redirect_to videos_url }
      format.json { head :ok }
    end
  end

	def show
		@present = Present.find(params[:id])
		if @present
			# TO DO 
		else
			# TO DO
		end
		respond_to do |format|
			format.json { render json: @present}
		end
	end
end
