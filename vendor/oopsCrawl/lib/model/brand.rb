class Brand

  include Mongoid::Document

  field :name, :type => String

  has_many :cnodes, :class_name => "Brand", :inverse_of => "pnode"
  belongs_to :pnode, :class_name => "Brand", :inverse_of => "cnodes"
  
  has_many :weibo_users, :class_name => "WeiboUser"

end