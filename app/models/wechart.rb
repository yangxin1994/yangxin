# encoding: utf-8
require 'uri'
require 'net/http'
require 'net/https'
require 'yaml'
require 'digest/md5'
require 'nokogiri'
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

  def self.mch_id
    @config['mch_id']
  end

  def self.nick_name
    @config['nick_name']
  end

  def self.send_name
    @config['send_name']
  end 

  def self.wxappid
    @config['wxappid']
  end   

  def self.apikey
    @config['apikey']
  end

  def self.jsapi_ticket
    ticket  = $redis.get('jsapi_ticket')
    unless ticket.present?
      ticket = refresh_jsapi_ticket
    end
    return ticket
  end

  def self.access_token
    token = $redis.get('access_token')
    unless token.present?
      token = refresh_access_token
    end
    return token
  end


  #定时任务 每1个小时执行一次
  def self.refresh_access_token
    uri = URI("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{self.appid}&secret=#{self.secret}")
    res = Net::HTTP.new(uri.host, uri.port)
    res.use_ssl = true
    res.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = res.get(uri.request_uri)
    res = JSON.parse(res.body)
    tok = res['access_token']
    $redis.set('access_token',tok)
    return token
  end


  # 定时任务 每一个小时执行一次
  def self.refresh_jsapi_ticket
    uri    = URI("https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=#{self.access_token}&type=jsapi")
    res = Net::HTTP.new(uri.host, uri.port)
    res.use_ssl = true
    res.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = res.get(uri.request_uri)
    res    = JSON.parse(res.body)
    ticket = res['ticket']
    $redis.set('jsapi_ticket',ticket)
    return ticket      
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

  #只有关注了公众号才能获取基本信息,如果没有关注的话,只会返回openid
  def self.get_user_info(openid)
    uri = URI("https://api.weixin.qq.com/cgi-bin/user/info?access_token=#{self.access_token}&openid=#{openid}&lang=zh_CN")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = http.get(uri.request_uri)
    res = JSON.parse(res.body)
    return res
  end

  def self.generate_sign(wechat_hash)
    wechat_hash    = JSON.parse(wechat_hash)
    stringA        = wechat_hash.sort.map{|e| e.join('=')}.join('&')
    stringSignTemp = stringA + "&key=#{Wechart.apikey}"
    sign           = Digest::MD5.hexdigest(stringSignTemp).upcase
    return   sign 
  end

  def self.send_red_pack(order_code,openid,ip,total_amount,min_value,max_value)
    uri = "https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack"
    #min_value 最小金额
    #max_value 最大金额
    #total_num 红包发放总人数
    #total_amount 付款金额
    nonce_str   = (0...32).map { ('a'..'z').to_a[rand(26)] }.join
    wechat_hash = {
      "nonce_str" =>nonce_str,
      "mch_billno" => order_code,
      "mch_id" => Wechart.mch_id,
      "wxappid" => Wechart.appid,
      "nick_name" => Wechart.nick_name,
      "send_name" => Wechart.send_name,
      "re_openid" => openid,
      "total_amount" => total_amount,
      "min_value" => min_value,
      "max_value" => max_value,
      "total_num" => 1,
      "wishing" => '感谢您参与问卷吧调研,祝您生活愉快!',
      "client_ip" => ip,
      "act_name" => '问卷吧红包大派送',
      "remark" => '分享到朋友圈,让更多人领红包'
    }

    tmp_json    = wechat_hash.to_json.dup.encode("UTF-8")
    sign        = generate_sign(tmp_json)
    wechat_hash.merge!({sign:sign})

    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.root {
        xml.sign sign
        xml.mch_billno order_code
        xml.mch_id Wechart.mch_id
        xml.wxappid Wechart.wxappid
        xml.nick_name Wechart.nick_name
        xml.send_name Wechart.send_name
        xml.re_openid openid
        xml.total_amount total_amount
        xml.min_value min_value
        xml.max_value max_value
        xml.total_num 1
        xml.wishing '感谢您参与问卷吧调研,祝您生活愉快!'
        xml.client_ip ip
        xml.act_name '问卷吧红包大派送'
        xml.remark '分享到朋友圈,让更多人领红包'
        xml.nonce_str nonce_str
      }
    end

    wechat_hash = builder.to_xml


    p12 = OpenSSL::PKCS12.new(File.read(Rails.root.to_s + '/apiclient_cert.p12'), "#{Wechart.mch_id}")
    uri = URI.parse("https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack")

    Net::HTTP.start(uri.host,uri.port,use_ssl:true,ca_file:Rails.root.to_s + '/rootca.pem',key:p12.key,cert:p12.certificate) do |http|
      request  = Net::HTTP::Post.new(uri.path)
      request.body = wechat_hash
      response = http.request(request)
      res      = Nokogiri::XML(response.body,nil,'UTF-8')
      # Rails.logger.info  '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
      # Rails.logger.info  res.inspect
      # Rails.logger.info  '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
      if res.css('return_code').text.match(/SUCCESS/) && res.css('result_code').text.match(/SUCCESS/)
        return true
      else
        if res.css('err_code').text.match(/TIME_LIMITED/)
          Rails.logger.info '=================================='
          Rails.logger.info '时间受限'
          Rails.logger.info '=================================='
        end
        return false
      end    
    end
  end 
end

























