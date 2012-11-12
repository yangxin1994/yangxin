class Admin::LotteriesController < Admin::ApplicationController
	
	def index
		render_json auto_paginate(Lottery.all)
	end

	def create
			@lottery = Lottery.create(params[:lottery])
			render_json @lottery.save do
				#Material.create(:material => params[:material], :materials => @lottery)
				@lottery.as_retval
			end
			# TODO add admin_id
	end

  def update
    @lottery = Lottery.find_by_id params[:id]
    render_json @lottery.update_attributes(params[:lottery]) do
      @lottery.as_retval
    end
  end
  
  def_each :for_publish, :activity, :finished do |method_name|
    @lottery = auto_paginate(Lottery.send(method_name))
    render_json { @lottery }
  end
  def show
    # TODO is owners request?
    render_json { Lottery.find_by_id(params[:id])}
  end
end
