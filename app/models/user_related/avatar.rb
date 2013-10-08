class Avatar
  
  extend CarrierWave::Mount

  attr_accessor :crop_w, :crop_h, :crop_x, :crop_y, :uid

  mount_uploader :image, AvatarUploader

  def set_and_store(id, crop, avatar)
    self.uid = id
    unless crop.empty?
      geo_arr = crop.split(',').reverse
      self.crop_w = geo_arr[0]
      self.crop_h = geo_arr[1]
      self.crop_x = geo_arr[2]
      self.crop_y = geo_arr[3]
    end
    self.image = avatar
    self.store_image!
  end
end