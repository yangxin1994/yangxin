require 'pp'
class Admin::MaterialsController < Admin::AdminController

	def create
    unless params["our-file"].nil?
      photo = ImageUploader.new
      photo.store!(params["our-file"])
      @material = params["our-file"] = photo.url
    end
    render :text => @material
    # render :inline => "<img src=\"#{@material}\" alt=\"\" id=\"prize_photo_src\">"
	end

end
