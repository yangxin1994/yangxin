class Admin::LotteriesController < Admin::ApplicationController
	
	def index
		respond_and_render_json Lottery.page(page)
	end

	def create
			@lottery = Lottery.create(params[:lottery])
			respond_and_render_json @lottery.save do
				#Material.create(:material => params[:material], :materials => @lottery)
				@lottery.as_retval
			end
			# TODO add admin_id
	end

  def update
    @lottery = Lottery.find_by_id params[:id]
    respond_and_render_json @lottery.update_attributes(params[:lottery]) do
      @lottery.as_retval
    end
  end
  
  def_each :for_publish, :activity, :finished do |method_name|
    @lottery = Lottery.send(method_name).page(page).per(per_page)
    respond_and_render_json { @lottery }
  end

end
