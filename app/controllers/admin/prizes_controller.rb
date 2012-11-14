class Admin::PrizesController < Admin::ApplicationController


  def index
    render_json { auto_paginate(Prize) }
  end


  def_each :virtual, :cash, :entity, :lottery, :stockout, :expired do |method_name|
    @prizes = auto_paginate(Prize.send(method_name))
    render_json { @prizes }
  end

  def for_lottery
    render_json { Prize.for_lottery }
  end

  def create
    # material = Material.create(:material_type => 1, 
    #                            :title => params[:prize][:name],
    #                            :value => params[:prize][:photo],
    #                            :picture_url => params[:prize][:photo])
    # params[:prize][:photo] = material
    @prize = Prize.create(params[:prize])
    # TODO add admin_id
    render_json @prize.save do
      #Material.create(:material => params[:material], :materials => @prize)
      @prize.as_retval
    end
  end

  def update
    @prize = Prize.find_by_id params[:id]
    unless params[:prize][:photo].nil?
      @prize.photo.value = params[:prize][:photo]
      @prize.photo.picture_url = params[:prize][:photo]
      @prize.photo.save
    end
    render_json @prize.update_attributes(params[:prize]) do
      @prize.as_retval
    end
  end
  
  def show
    @prize = Prize.find_by_id(params[:id])
    @prize[:photo_src] = @prize.photo.picture_url
    render_json { @prize }
  end

  def destroy
    @prize = Prize.find_by_id(params[:id])
    render_json @prize.is_valid? do |g|
      @prize.update_attribute('is_deleted', true) if g
    end
  end
end