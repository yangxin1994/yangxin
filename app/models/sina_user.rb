
class SinaUser < ThirdPartyUser
  
  field :name, :type => String
  field :location, :type => String
  field :description, :type => String
  field :gender, :type => String
  field :profile_image_url, :type => String
  
end
