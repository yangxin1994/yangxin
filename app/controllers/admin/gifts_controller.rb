class Admin::GiftsController < Admin::ApplicationController


  def index
    render_json { auto_paginate(Gift) }
  end


  def_each :virtual, :cash, :entity, :stockout, :expired do |method_name|
    @gifts = auto_paginate(Gift.send(method_name))
    render_json { @gifts }
  end

  def create
    material = Material.create(:material_type => 1, 
                               :title => params[:gift][:name],
                               :value => params[:gift][:photo],
                               :picture_url => params[:gift][:photo])
    params[:gift][:photo] = material
    @gift = Gift.create(params[:gift])
    # TODO add admin_id
    render_json @gift.save do
      #Material.create(:material => params[:material], :materials => @gift)
      @gift.as_retval
    end
  end

  def update
    @gift = Gift.find_by_id params[:id]
    unless params[:gift][:photo].nil?
      @gift.photo.value = params[:gift][:photo]
      @gift.photo.picture_url = params[:gift][:photo]
      @gift.photo.save
    end
    render_json @gift.update_attributes(params[:gift]) do
      @gift.as_retval
    end
  end
  
  def show
    @gift = Gift.find_by_id(params[:id])
    @gift[:photo_src] = @gift.photo.picture_url
    render_json { @gift }
  end

  def destroy
    @gift = Gift.find_by_id(params[:id])
    render_json @gift.is_valid? do |g|
      @gift.update_attribute('is_deleted', true) if g
    end
  end
end