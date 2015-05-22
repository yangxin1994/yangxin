# encoding: utf-8
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

  def self.add_new_user(opt)
    puts '------------创建wechart_user----------'
    puts "------------openid:#{opt['open_id']}---"
    wuser = self.create(openid:opt['open_id'])
    Order.where(:type => Order::HONGBAO,:open_id => opt['open_id'],:wechart_user_id => nil).each do |order|
      order.update_attributes(wechart_user:wuser.id.to_s)
    end
  end

  def get_basic_info
    opt = Wechart.get_user_info(self.openid)
    puts '------------更新wechart_user----------'
    puts "------------openid:#{self.openid}----"
    puts opt.inspect
    puts '-------------------------------------'
    self.nickname       = opt['nickname']
    self.sex            = opt['sex'].to_i
    self.country        = opt['country']
    self.province       = opt['province']
    self.city           = opt['city']
    self.language       = opt['language']
    self.headimgurl     = opt['headimgurl']
    self.subscribe_time = opt['subscribe_time'].to_i
    self.subscribe      = opt['subscribe'].to_i
    self.save
  end

end