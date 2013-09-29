require 'tool'
class Prize
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  NORMAL = 1
  DELETED = 2

  VIRTUAL = 1
  REAL = 2
  MOBILE_CHARGE = 4
  ALIPAY = 8
  JIFENBAO = 16
  QQ_COIN = 32

  DEFAULT_IMG = '/assets/od-quillme/gifts/default.png'


  # 1 normal, 2 deleted
  field :status, :type => Integer, default: NORMAL
  # 1 for virtual prize, 2 for real prize
  field :type, :type => Integer, default: REAL
  field :title, :type => String, default: ""
  field :description, :type => String, default: ""
  field :amount, :type => Integer, default: 1
  field :price,:type => Float, default: 0.0

  has_one :photo, :class_name => "Material", :inverse_of => 'prize'
  has_many :orders

  default_scope order_by(:created_at.desc)
  scope :normal, where(:status => NORMAL)
  scope :real, normal.where(:type => REAL)
  scope :virtual, normal.where(:type => VIRTUAL)

  index({ created_at: -1 }, { background: true } )
  index({ status: 1 }, { background: true } )
  index({ title: 1 }, { background: true } )
  index({ type: 1, status: 1 }, { background: true } )
  index({ _id: 1, created_at: -1 }, { background: true } )


  def self.create_prize(prize)
    photo_url = prize.delete("photo_url")
    material = Material.create_image(photo_url)
    prize = Prize.new(prize)
    prize.save
    prize.photo = material
    prize["photo_url"] = material.picture_url
    return prize
  end

  def self.search_prize(title, type)
    prizes = Prize.normal
    prizes = prizes.where(:title => /#{title}/) if !title.blank?
    prizes = prizes.where(:type.in => Tool.convert_int_to_base_arr(type)) if !type.blank? && type != 0
    prizes.each do |p|
        p["photo_url"] = p.photo.try(:picture_url)
    end
    return prizes
  end


  def update_prize(prize)
    photo_url = prize.delete("photo_url")
    if !photo_url.blank? && photo_url != self.photo.try(:picture_url)
        material = Material.create_image(photo_url)
        self.photo = material
    end
    return self.update_attributes(prize)
  end

  def delete_prize
    self.status = DELETED
    return self.save
  end

  # add for lottery show page
  def photo_src
    self.photo.present? ? self.photo.picture_url : Prize::DEFAULT_IMG
  end
end
