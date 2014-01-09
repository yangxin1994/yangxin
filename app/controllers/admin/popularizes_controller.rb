class Admin::PopularizesController < Admin::AdminController
  before_filter :require_sign_in

  layout "layouts/admin-todc"

  def index
    @banners = auto_paginate Banner.all
  end

  def create  
    banner = Banner.new(params[:banner]) 
    current_user.banners << banner
    redirect_to :action => :index
  end

  def destroy
    banner = Banner.find_by_id(params[:id])
    if banner.destroy
      render_json_auto(true)
    end
  end

  def sort
    params[:ids].each_with_index do |bid,idx|
      banner = Banner.find_by_id(bid)
      if banner.present?
        banner.update_attributes(:pos => (idx + 1))
      end
    end
    render_json_auto(true)
  end
  
end
