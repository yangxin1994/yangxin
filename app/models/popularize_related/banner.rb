# encoding: utf-8
class Banner
  
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool
  mount_uploader :image, BannerUploader

  OPENED = 2
  DELETED = 4

  
  field :image, :type => String
  field :status, :type => Integer,:default => 2
  field :pos, :type => Integer,:default => 1

  belongs_to :user, class_name: "User", inverse_of: :banners

  scope :opened, -> { where(:status => 2) }
  scope :deleted, -> { where(:status => 4) }
  default_scope asc(:pos)

  before_create :get_max_position

  protected

  def  get_max_position
    self.pos = ( Banner.max(:pos).to_i + 1 )
  end

  
end
