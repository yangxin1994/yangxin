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

end
