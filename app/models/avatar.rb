class Avatar
	extend CarrierWave::Mount

	attr_accessor :crop_w, :crop_h, :crop_x, :crop_y, :uid

	mount_uploader :image, AvatarUploader
end