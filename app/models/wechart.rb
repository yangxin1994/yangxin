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
  	Rails.logger.info '------------------'
  	Rails.logger.info code
  	Rails.logger.info '------------------'
    uri = URI("https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{self.appid}&secret=#{self.secret}&code=#{code}&grant_type=authorization_code")
    res = Net::HTTP.get(uri)
    Rails.logger.info '========================================='
    Rails.logger.info res.inspect
    Rails.logger.info '========================================='	
  end 
end