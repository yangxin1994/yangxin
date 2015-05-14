class WechartUser
  include Mongoid::Document
  include Mongoid::Timestamps 
  include FindTool 
  MALE    = 1
  FEMALE  = 2
  UNKNOWN = 0

  SUBSCRIBE = 1  #已关注该公众账号
  UNSUBSCRIBE = 0 #未关注该公众账号

  field :openid,type:String
  field :nickname,type:String
  field :sex,type:Integer
  field :country,type:String
  field :province,type:String
  field :city,type:String
  field :language,type:String
  field :headimgurl,type:String
  field :subscribe_time,type:Integer # 最后关注的时间
  field :subscribe,type:Integer
  has_many :orders
  after_create :get_basic_info


  def self.subscribe(openid)
    info = self.where(openid:openid).first
    unless info.present?
      self.create(openid:openid)
    else
      info.get_basic_info
    end
  end

  def self.unsubscribe(openid)
    info = self.where(openid:openid).first
    info.update_attributes(subscribe:UNSUBSCRIBE)
  end

  def get_basic_info
    info_hash           = Wechart.get_user_info(self.openid)
    self.nickname       = info_hash['nickname']
    self.sex            = info_hash['sex'].to_i
    self.country        = info_hash['country']
    self.province       = info_hash['province']
    self.city           = info_hash['city']
    self.language       = info_hash['language']
    self.headimgurl     = info_hash['headimgurl']
    self.subscribe_time = info_hash['subscribe_time'].to_i
    self.subscribe      = info_hash['subscribe'].to_i
    self.save   
  end

end