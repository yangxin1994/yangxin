class PresentsController < ApplicationController
	# presents.json?page=1
	def index
		@presents = Present.page(params[:page].to_i)
		respond_to do |format|
			format.json { render json: @presents, :only => [:name, :point] }
		end
	end

	def self.def_each(*method_names, &block)
		method_names.each do |method_name|
			define_method method_name do
				instance_exec method_name, &block
			end
		end
	end

	def_each :virtual_goods, :cash, :real_goods do |method_name|
		flash[:notice] = "No Goods" unless @presents = Present.send((method_name.to_s + "_present").to_sym).can_be_rewarded.page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @presents }
		end
	end

	def create		
    respond_to do |format|
      if @topic.Present.create(params[:present])
        format.html { redirect_to :action => 'show',:id => @topic.name }
        #format.json { render json: @topic, status: :created, location: @topic }
      else
        format.html { render action: "new" }
        #format.json { render json: @topic.errors, status: :unprocessable_entity }
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
