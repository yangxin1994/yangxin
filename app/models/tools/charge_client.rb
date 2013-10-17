# encoding: utf-8
require 'securerandom'
require 'digest/md5'
require 'iconv'
class ChargeClient

  include HTTParty

  base_uri Rails.application.config.ofcard_service_uri
  format :xml

  attr_accessor :uri_prefix, :userid, :userpws, :version

  @@gbk2utf8 = Iconv.new("utf-8", "gbk")
  
  def initialize
      @uri_prefix = ""
      @userid = "A830057"
      @userpws = Digest::MD5.hexdigest('oopsdata@2013')
      @version = "6.0"
      @mobile_card_id = "140101"
      @qq_card_id = "220612"
  end

  # http://api2.ofpay.com/queryuserinfo.do?userid=A830057&userpws=#{md5(password)}&version=6.0
  def query_balance
      retval = _get({}, "/queryuserinfo")
      return retval["userinfo"]
  end

  # http://api2.ofpay.com/telcheck.do?phoneno=#{phone_number}&price=#{prive}&userid=A830057
  def is_chargable?(phone_number, price)
      
      retval = _get({"phoneno" => phone_number, "price" => price}, "/telcheck", "")
      result = retval.split('#')
      return {"is_chargable" => (result[0].to_i == 1), "message" => @@gbk2utf8.iconv(result[1])}
  end

  # http://api2.ofpay.com/mobinfo.do?mobilenum=1348888
  def mobile_info(phone_number)
      retval = _get({"mobilenum" => phone_number[0..6]}, "/mobinfo", "")
      return @@gbk2utf8.iconv(retval)
  end

  # http://api2.ofpay.com/onlineorder.do?
  # userid=A830057&userpws=#{md5(password)}&cardid=140101&cardnum=#{price}&sporder_id=#{SecureRandom.uuid}
  # &sporder_time=#{Time.now.strftime('%Y%m%d%H%M%S')}&game_userid=#{phone_number}
  # &md5_str=xxxxxxxxxxxxx&ret_url=xxxxx&version=6.0
  def mobile_charge(phone_number, price, sporder_id)
      sporder_time = Time.now.strftime('%Y%m%d%H%M%S')
      md5_content = @userid + @userpws + @mobile_card_id + price.to_s + sporder_id +
          sporder_time + phone_number + Rails.application.config.ofcard_key_str
      md5_str = Digest::MD5.hexdigest(md5_content).upcase
      retval = _get({"cardid" => @mobile_card_id,
                      "cardnum" => price,
                      "sporder_id" => sporder_id,
                      "sporder_time" => sporder_time,
                      "game_userid" => phone_number,
                      "md5_str" => md5_str,
                      "ret_url" => Rails.application.config.ret_url},
                      "/onlineorder")
      return retval["orderinfo"]
  end

  def qq_charge(qq_number, price, sporder_id)
      sporder_time = Time.now.strftime('%Y%m%d%H%M%S')
      md5_content = @userid + @userpws + @qq_card_id + price.to_s + sporder_id +
          sporder_time + qq_number + Rails.application.config.ofcard_key_str
      md5_str = Digest::MD5.hexdigest(md5_content).upcase
      retval = _get({"cardid" => @qq_card_id,
                      "cardnum" => price,
                      "sporder_id" => sporder_id,
                      "sporder_time" => sporder_time,
                      "game_userid" => qq_number,
                      "md5_str" => md5_str,
                      "ret_url" => Rails.application.config.ret_url},
                      "/onlineorder")
      return retval["orderinfo"]
  end

  # http://api2.ofpay.com/reissue.do?
  # userid=A830057&userpws=b0c4ced5ed0723bbedb1241dc2f0e886&
  # spbillid=514bbd80455e0167d5000004&version=6.0
  def reissue_status(sporder_id)
      retval = _get({"spbillid" => sporder_id},
                      "/reissue")
      return retval
  end



  ############## not use #################
  def query_order(sporder_id)
      retval = _get({"spbillid" => sporder_id}, "query", "", false, "do", "http://202.102.53.141:83/api/")
  end

  def query_card_info(cardid)
      retval = _get({"cardid" => cardid}, "/querycardinfo")
      return retval
  end
  ########################################


  # construct real resource uri
  def _uri(uri, absolute = false, format = "do")
      return absolute ? "#{uri}.#{format}" : "#{uri_prefix}#{uri ? uri : ''}.#{format}"
  end
  
  # construct action options
  def _options(params, is_get = false)
      value = {
          :userid => @userid,
          :userpws => @userpws,
          :version => @version
      }.merge!(params)
      return is_get ? { :query => value } : { :body => value.to_json, :headers => { 'Content-Type' => 'application/json' }  }
  end
  
  # return legal response value
  def _return(response, format = "xml")
      begin
          # Rails.logger.debug response.inspect
          case format.to_s
          when "xml"
              return Hash.from_xml(response.body)
          when ""
              return response.body
          end
      rescue Exception => err
          Rails.logger.error err
      end
  end

  def with_different_base_uri(base_uri, &block)
      temp_base_uri = ""
      if !base_uri.blank?
          temp_base_uri = BaseClient.base_uri
          self.class.base_uri(base_uri)
      end
      block.yield
      BaseClient.base_uri(temp_base_uri) if !temp_base_uri.blank?
  end

  def _get(params, uri=nil, retval_format = "xml", absolute = false, format = "do", base_uri = "")
      result = nil
      with_different_base_uri(base_uri) do
          begin
              result = self.class.get(_uri(uri, absolute, format), _options(params, true))
          rescue Exception => err
              Rails.logger.error err
          end
      end
      return _return(result, retval_format)
  end
  
  def _post(params, uri=nil, absolute = false, format = "do", base_uri = "")
      result = nil
      with_different_base_uri(base_uri) do
          begin
              result = self.class.post(_uri(uri, absolute, format), _options(params))
          rescue Exception => err
              Rails.logger.error err
          end
      end
      _return(result)
  end
  
  def _delete(params, uri=nil, absolute = false, format = "do", base_uri = "")
      result = nil
      with_different_base_uri(base_uri) do
          begin
              result = self.class.delete(_uri(uri, absolute, format), _options(params))
          rescue Exception => err
              Rails.logger.error err
          end
      end
      _return(result)
  end
  
  def _put(params, uri=nil, absolute = false, format = "do", base_uri = "")
      result = nil
      with_different_base_uri(base_uri) do
          begin
              result = self.class.put(_uri(uri, absolute, format), _options(params))
          rescue Exception => err
              Rails.logger.error err
          end
      end
      _return(result)
  end
end
