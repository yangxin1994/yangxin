class WeiboUser
  include Mongoid::Document

  field :wid               , :type => String  # 用户UID
  field :idstr             , :type => String  # 字符串型的用户UID
  field :screen_name       , :type => String  # 用户昵称
  field :name              , :type => String  # 友好显示名称
  field :province          , :type => Integer # 用户所在省级ID
  field :city              , :type => Integer # 用户所在城市ID
  field :location          , :type => String  # 用户所在地
  field :university        , :type => String  # 用户大学
  field :mschool           , :type => String  # 用户中学
  field :tags              , :type => String  # 用户标签
  field :company           , :type => String  # 用户公司
  field :birth             , :type => String  # 用户生日
  field :blood_type        , :type => String  # 用户血型
  field :description       , :type => String  # 用户个人描述
  field :url               , :type => String  # 用户博客地址
  field :profile_image_url , :type => String  # 用户头像地址（中图），50×50像素
  field :profile_url       , :type => String  # 用户的微博统一URL地址
  # field :domain            , :type => String  # 用户的个性化域名
  field :weihao            , :type => String  # 用户的微号
  field :gender            , :type => String  # 性别，m：男、f：女、n：未知
  field :followers_count   , :type => Integer # 粉丝数
  field :friends_count     , :type => Integer # 关注数
  field :statuses_count    , :type => Integer # 微博数
  field :favourites_count  , :type => Integer # 收藏数
  field :created_at        , :type => String  # 用户创建（注册）时间
  field :following         , :type => Boolean # 暂未支持
  # field :allow_all_act_msg , :type => Boolean # 是否允许所有人给我发私信，true：是，false：否
  # field :geo_enabled       , :type => Boolean # 是否允许标识用户的地理位置，true：是，false：否
  field :verified          , :type => Boolean # 是否是微博认证用户，即加V用户，true：是，false：否
  field :verified_type     , :type => Integer # 暂未支持
  field :remark            , :type => String  # 用户备注信息，只有在查询用户关系时才返回此字段
  field :status            , :type => Hash    # 用户的最近一条微博信息字段 详细
  field :allow_all_comment , :type => Boolean # 是否允许所有人对我的微博进行评论，true：是，false：否
  field :avatar_large      , :type => String  # 用户头像地址（大图），180×180像素
  field :avatar_hd         , :type => String  # 用户头像地址（高清），高清头像原图
  field :verified_reason   , :type => String  # 认证原因
  field :follow_me         , :type => Boolean # 该用户是否关注当前登录用户，true：是，false：否
  field :online_status     , :type => Integer # 用户的在线状态，0：不在线、1：在线
  field :bi_followers_count, :type => Integer # 用户的互粉数
  field :lang              , :type => String  # 用户当前的语言版本，zh-cn：简体中文，zh-tw：繁体中文，en：英语
  field :approve           , :type => Boolean, :default => false # 个人认证
  field :approve_co        , :type => Boolean, :default => false # 商业认证
  field :identity_info     , :type => String # 商业认证
  field :marriage          , :type => String # 婚姻状态
  field :luid              , :type => String # page_id

  field :follow_count      , :type => Integer, :default => 0
  field :fans_count        , :type => Integer, :default => 0
  field :weibo_count       , :type => Integer, :default => 0

  has_many :weibos
  has_and_belongs_to_many :weibo_artists
  has_and_belongs_to_many :movies, class_name: "Movie"
  has_and_belongs_to_many :follows, class_name: "WeiboUser", :inverse_of => :fans
  has_and_belongs_to_many :fans, class_name: "WeiboUser", :inverse_of => :follows
  belongs_to :brand

  def self.group_by_location
    criteria.group_by{|a| a.location.to_s.split(' ')[0]}
  end

  def self.group_by_marriage
    criteria.group_by{|a| a.marriage }
  end

  def self.group_by_marriage_count(is_ori = false)
    ac = where(:marriage => /[\d\D]+/).count
    return {} if ac == 0
    m = group_by_marriage.map{|a,b| {a => b.count * 100 / ac }}.inject(:merge)
    if is_ori
      return m
    else
      {
        "单身" => m["单身"].to_i + m["暗恋中"].to_i + m["恋爱中"].to_i + m["暧昧中"].to_i + m["求交往"].to_i,
        "已婚" => m["已婚"].to_i + m["丧偶"].to_i + m["订婚"].to_i,
        "离异" => m["离异"].to_i + m["分居"].to_i
      }
    end
  end 

  def self.group_by_location_count
    ac = where(:location => /[\d\D]+/).count
    return [] if ac == 0
    group_by_location.map{|a,b| {a => b.count * 100 / ac }}.inject(:merge).sort_by{|a, v| v}.delete_if{|a, v| a == "其他" || a == nil}.last(5).reverse
  end

  def self.group_by_location_count_all
    ac = where(:location => /[\d\D]+/).count
    return [] if ac == 0
    group_by_location.map{|a,b| {a => b.count * 100 / ac }}.inject(:merge).sort_by{|a, v| v}.delete_if{|a, v| ["香港", "澳门", "其他", "台湾", "海外", nil].include?(a)}.map{|a| {name: a[0], value: a[1]} }
  end

  def get_url
    return self.url if self.url
    self.url = "http://weibo.com/#{wid}"
    save
    self.url
  end
end