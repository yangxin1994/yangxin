class Admin::GiftsController < Admin::ApplicationController

  def create
    @gift = Gift.create(params[:gift])
    # TODO add admin_id
    respond_and_render_json @gift.save do
      #Material.create(:material => params[:material], :materials => @gift)
      @gift.as_retval
    end
  end

  def update
    @gift = Gift.find(params[:id])
    respond_and_render_json @gift.update_attributes(params[:gift]) do
      @gift.as_retval
    end
  end

  def destroy
    respond_and_render_json do
      params[:ids].to_a.each do |id|
        Gift.find_by_id id do |r|
          r.delete
        end
      end
    end
  end
end