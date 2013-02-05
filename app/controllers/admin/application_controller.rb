class Admin::ApplicationController < ApplicationController
	before_filter :require_admin

	def create_photo(param)
		return false unless params[param][:photo]
    photo = Material.create(:material_type => 1, 
                    				:title => params[param][:name],
                    				:value => params[param][:photo],
                    				:picture_url => params[param][:photo])
    params[param][:photo] = photo
	end

	def update_photo(param, ins)
    unless params[param][:photo].nil?
      if ins.photo.nil?
	 			ins.photo = create_photo(param)
	 		else
	      ins.photo.title = params[param][:name]
	      ins.photo.value = params[param][:photo]
	      ins.photo.picture_url = params[param][:photo]	 			
      end
      params[param].delete(:photo)
      ins.photo.save
    end
	end

	def create_lottery(param)

	end
end