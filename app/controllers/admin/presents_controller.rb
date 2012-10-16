class Admin::PresentsController < Admin::ApplicationController

  def create
    @present = Present.create(params[:present])
    # TODO add admin_id
    respond_and_render_json @present.save do
      Material.create(:material => params[:material], :materials => @present)
      @present.as_retval
    end
  end

  def expired
    respond_and_render_json { Present.expired.page(page)}
  end

  def update
    @present = Present.find(params[:id])
    respond_and_render_json @present.update_attributes(params[:present]) do
      @present.as_retval
    end
  end

  def delete
    respond_and_render_json do
      params[:ids].to_a.each do |id|
        Present.find_by_id id do |r|
          r.delete
        end
      end
    end
  end
end