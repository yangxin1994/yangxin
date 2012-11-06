class Admin::GiftsController < Admin::ApplicationController


  def index
    respond_and_render_json { Gift.page(page).per(per_page) }
  end


  def_each :virtualgoods, :cash, :realgoods, :stockout, :expired do |method_name|
    @gifts = Gift.send(method_name).page(page).per(per_page)
    respond_and_render_json { @gifts}
  end

  def create
    @gift = Gift.create(params[:gift])
    # TODO add admin_id
    respond_and_render_json @gift.save do
      #Material.create(:material => params[:material], :materials => @gift)
      @gift.as_retval
    end
  end

  def update
    @gift = Gift.find_by_id params[:id]
    respond_and_render_json @gift.update_attributes(params[:gift]) do
      @gift.as_retval
    end
  end
  
  def show
    # TO DO is owners request?
    respond_and_render_json { Gift.find_by_id(params[:id]) }
  end

  def destroy
    @gift = Gift.find_by_id(params[:id])
    respond_and_render_json @gift.is_valid? do |g|
      @gift.update_attribute('is_deleted', true) if g
    end
  end
end