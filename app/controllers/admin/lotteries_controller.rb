class Admin::LotteriesController < Admin::ApplicationController
	
	def index
		render_json { auto_paginate(Lottery.all)}
	end

	def create
    material = Material.create(:material_type => 1, 
                               :title => params[:lottery][:title],
                               :value => params[:lottery][:photo],
                               :picture_url => params[:lottery][:photo])
    # logger.info "=========#{params[:lottery][:photo]}========="
    params[:lottery][:photo] = material

    lp_ids = params[:lottery][:prize_ids]
    params[:lottery][:prize_ids] = nil
		@lottery = Lottery.new(params[:lottery])
    lp_ids.each do |i|
      lp = Prize.where("_id"=> i).first
      @lottery.prizes << lp #unless lp.nil?
      lp.save
    end unless lp_ids.nil?
    @lottery.photo = material
    material.save
    render_json @lottery.save do
				#Material.create(:material => params[:material], :materials => @lottery)
	    @lottery.as_retval
		end
			# TODO add admin_id
	end

  def update
    @lottery = Lottery.find_by_id params[:id]
    unless params[:lottery][:photo].nil?
      if @lottery.photo.nil?
        material = Material.create(:material_type => 1, 
                                   :title => params[:lottery][:name],
                                   :value => params[:lottery][:photo],
                                   :picture_url => params[:lottery][:photo])
        
        @lottery.photo = material
      end
      @lottery.photo.value = params[:lottery][:photo]
      @lottery.photo.picture_url = params[:lottery][:photo]
      params[:lottery][:photo] = material
      @lottery.photo.save
    end
    lp_ids = params[:lottery][:prize_ids]
    params[:lottery][:prize_ids] = nil
    @lottery = Lottery.new(params[:lottery])
    lp_ids.each do |i|
      lp = Prize.where("_id"=> i).first
      @lottery.prizes << lp #unless lp.nil?
      lp.save
    end unless lp_ids.nil?
    # @lottery = Lottery.find_by_id params[:id]
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
    @lottery = Lottery.find_by_id(params[:id])
    @lottery[:prizes] = @lottery.prizes
    @lottery[:photo_src] = @lottery.photo.picture_url unless @lottery.photo.nil?
    render_json { @lottery}
  end
  def destroy
    render_json do
      Lottery.find_by_id(params[:id]) do |e|
        e.update_attribute("is_deleted", true)
      end
    end 
  end
end
