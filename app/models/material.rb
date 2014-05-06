require 'error_enum'
require 'securerandom'
class Material

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  # 1 for image, 2 for video, 4 for audio, 8 for local image, 16 for local video, 32 for local audio
  field :material_type, :type => Integer
  field :title, :type => String
  field :value, :type => String
  field :picture_url, :type => String

  belongs_to :gift, :inverse_of => 'photo'
  belongs_to :prize, :inverse_of => 'photo'
  belongs_to :lottery, :inverse_of => 'photo'
  belongs_to :user
  belongs_to :user,:inverse_of => 'avatar'

  before_save :set_picture_url

  def self.create_image(image_url)
    material = Material.new(:material_type => 1, :value => image_url, :picture_url => image_url)
    material.save
    return material
  end

  def self.check_and_create_new(current_user, material)
    return ErrorEnum::WRONG_MATERIAL_TYPE unless [1, 2, 4, 8, 16, 32].include?(material["material_type"].to_i)
    # video and audio
    if material["material_type"].to_i != 1
      material["value"] = material["value"].gsub('thumb_','').split('.').first
    end 

    Rails.logger.info('---------------------------------------')
    Rails.logger.info(material["value"])
    Rails.logger.info(material["picture_url"])
    Rails.logger.info('---------------------------------------')

    material_inst = Material.new(:material_type => material["material_type"].to_i,
      :value => material["value"],
      :title => material["title"],
      :picture_url => material["picture_url"])
    material_inst.save
    if !current_user.nil?
      current_user.materials << material_inst
      current_user.save
    end
    return material_inst
  end

  def self.find_by_type(material_type)
    return [] if !(1..63).to_a.include?(material_type)
    materials = []
    Material.all.each do |material|
      materials << material if material.material_type & material_type > 0
    end
    return materials
  end

  def set_picture_url
    if material_type == 1
      picture_url ||= '/assets/images/img.png'
    end
  end

  def update_material(material)
    self.update_attributes(:material_type => material["material_type"],
      :value => material["value"],
      :title => material["title"],
      :picture_url => material["picture_url"])
    return self.save
  end
end
