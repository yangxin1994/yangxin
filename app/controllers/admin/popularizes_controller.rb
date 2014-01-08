class Admin::PopularizesController < Admin::AdminController
  before_filter :require_sign_in

  layout "layouts/admin-todc"

  def index
    @banners = auto_paginate Banner.all
  end
  
end
