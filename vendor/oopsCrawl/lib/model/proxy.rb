class Proxy

  include Mongoid::Document

  field :ip        , :type => String
  field :port      , :type => String
  field :location  , :type => String
  field :type      , :type => String 
  field :speed     , :type => Float
  field :conn      , :type => Float
  field :created_at, :type => Integer
  field :last_use  , :type => Integer, :default => 0
  field :last_confirm  , :type => Integer, :default => 0
  field :is_deleted, :type => Boolean, :default => false
  field :is_confirm, :type => Boolean, :default => false

  has_many :accounts
  
  validates :ip, presence: true, uniqueness: true
  validates :port, presence: true
  validates :type, presence: true

  scope :all_http, ->{ where(:is_deleted => false).where(:type => "HTTP").where(:speed.lt => 8.0).asc(:last_use).asc(:speed) }
  scope :fast, ->{ where(:is_deleted => false).where(:speed.lt => 6.0).asc(:last_use).desc(:created_at).asc(:speed) }
  scope :all_https, ->{ where(:type => "HTTPS").desc(:last_use).where(:speed.lt => 8.0).asc(:last_use).asc(:speed) }
  scope :location_at, ->(_location){ where(:location => /#{_location}/) }

  def self.get_one(_location = nil)
    _ps = _location ? fast.location_at(_location) : fast
    if proxy = _ps.first
      proxy.last_use = Time.now
      proxy.save
      return proxy
    end
    nil
  end

  def self.reset
    each{|a| a.is_deleted = false;a.save}
    true
  end

  def host
    "#{type.downcase}://#{ip}"
  end

  def self.confirm(_ec = 5)
    ts = []
    fast.each_slice(_ec) do |_proxies|
      ts << Thread.fork{
        _proxies.each do |proxy|
          proxy.confirm
        end
      }
    end
  end

  def confirm
    return if self.last_confirm + 3.hours > Time.now.to_i 
    self.last_confirm = Time.now
    self.save
    http_client = Mechanize.new
    # proxy = URI.parse("http://183.221.186.116:8123")
    http_client.set_proxy(ip, port)
    http_client.user_agent_alias = 'Mac Safari'
    _ip = ""
    p "ready confirm"
    begin
      http_client.get("http://www.ip.cn/") do |page|
        _ip = page.search("#result code").text
      end
    rescue Exception => e
      self.destroy
    end

    if _ip != self.ip
      self.destroy
    else
      self.is_confirm = true
    end
    p "confirm result: #{_ip == self.ip}"
    save
    _ip == self.ip
  end

end