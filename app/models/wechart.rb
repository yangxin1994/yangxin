# encoding: utf-8
require 'net/http'
require 'net/https'
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


  def self.access_token
    token = $redis.get('access_token')
    unless token.present?
      token = @config['access_token']
    end
    return token
  end
  

  #定时任务 每1个小时执行一次
  def self.refresh_access_token
    uri = URI("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{self.appid}&secret=#{self.secret}")
    res = Net::HTTP.get(uri)
    res = JSON.parse(res)
    tok = res['access_token']
    $redis.set('access_token',tok)
    data = YAML.load_file "#{Rails.root}/config/wechart.yml"
    data["#{Rails.env}"]["access_token"] = tok
    File.open("#{Rails.root}/config/wechart.yml", 'w') { |f| YAML.dump(data, f) }
  end

  def self.get_open_id(code)
    uri = URI.parse("https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{self.appid}&secret=#{self.secret}&code=#{code}&grant_type=authorization_code")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = http.get(uri.request_uri)
    res = JSON.parse(res.body)
    return res['openid']
  end

  def self.get_user_info(opt)
    openid = opt[:open_id]
    uri = URI("https://api.weixin.qq.com/cgi-bin/user/info?access_token=#{self.access_token}&openid=#{openid}&lang=zh_CN")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = http.get(uri.request_uri)
    res = JSON.parse(res.body)
    puts '==================================='
    puts res.inspect
    puts '==================================='
    return res
  end


  def self.send_red_pack(order_id,openid)
    uri = "https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack"
    wechat_hash = {
    	nonce_str:(0...32).map { ('a'..'z').to_a[rand(26)] }.join,
    	sign:generate_sign,
    	mch_billno:order_id,
    	mch_id:Wechart.mch_id,
    	wxappid:Wechart.appid,
    	nick_name:Wechart.nick_name,
    	send_name:Wechart.send_name,
    	re_openid:openid,
    	total_amount:1,
    	min_value:1,
    	max_value:1,
    	total_num:1,
    	wishing:'感谢您参与问卷吧调研,祝您生活愉快!',
    	client_ip:'127.0.0.1',
    	act_name:'问卷标题',
    	remark:'分享到朋友圈,让更多人领红包'
    }

    res = Typhoeus::Request.post(uri, body: wechat_hash.to_json)
    Rails.logger.info '-------------------------------------'
    Rails.logger.info res.inspect
    Rails.logger.info '-------------------------------------'
    return res
  end 
end

























