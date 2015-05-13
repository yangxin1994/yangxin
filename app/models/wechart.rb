require 'net/http'
require 'yaml'
class Wechart

  @config = YAML.load_file("#{Rails.root.to_s}/config/wechart.yml")[Rails.env]
  
  def self.appid
    @config['appid']
  end

  def self.secret
    @config['secret']
  end

  def self.token
    @config['token']
  end

  def self.redirect_uri
    @config['redirect_uri']
  end 

  def self.get_open_id(code)
	uri = URI.parse("https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{self.appid}&secret=#{self.secret}&code=#{code}&grant_type=authorization_code")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	res = http.get(uri.request_uri)
    res = JSON.parse(res)
    return res['openid']
  end 
end