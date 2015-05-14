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

  def self.create_new(opt)
    wuser = self.create()
    wuser.openid         = opt['openid']
    wuser.nickname       = opt['nickname']
    wuser.sex            = opt['sex'].to_i
    wuser.country        = opt['country']
    wuser.province       = opt['province']
    wuser.city           = opt['city']
    wuser.language       = opt['language']
    wuser.headimgurl     = opt['headimgurl']
    wuser.subscribe_time = opt['subscribe_time'].to_i
    wuser.subscribe      = opt['subscribe'].to_i
    wuser.save  
    puts '&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
    puts wuser.inspect
    puts '&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&' 
  end

end