# encoding: utf-8
require 'securerandom'
require 'digest/md5'
require 'iconv'
class EsaiApi

  include HTTParty

  base_uri Rails.application.config.esai_service_uri
  format :xml

  attr_accessor :uri_prefix, :user_number, :sign

  @@gbk2utf8 = Iconv.new("utf-8", "gbk")
  @@order_index = 0
  
  def initialize
    @uri_prefix = ""
    @user_number = 8000039
    @sign = "c95c1dce92d1502a99a233e47a84f699"
  end

  def with_different_base_uri(base_uri, &block)
      temp_base_uri = ""
      if !base_uri.blank?
          temp_base_uri = self.class.base_uri
          self.class.base_uri(base_uri)
      end
      block.yield
      self.class.base_uri(temp_base_uri) if !temp_base_uri.blank?
  end

  # curl -X POST --data "UserNumber=8000039&PhoneNumber=13488881477&Province=Auto&City=Auto&PhoneClass=Auto&PhoneMoney=10&Time=2014-5-12 12:55:00&RecordKey=5BE69723C9867589" http://www.esaipai.com/IF/EIFPHONE/CHECKPHONE
  def check_phone(phone_number, amount)
    time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    key = Digest::MD5.hexdigest("#{@user_number}#{phone_number}AutoAutoAuto#{amount}#{time}#{@sign}")[0..15].upcase
    params = {"UserNumber" => @user_number,
      "PhoneNumber" => phone_number,
      "Province" => "Auto",
      "City" => "Auto",
      "PhoneClass" => "Auto",
      "PhoneMoney" => amount,
      "Time" => time,
      "RecordKey" => key}
    retval = self.class.post("/CHECKPHONE", {body: params})
    parsed_result = Nokogiri::XML(retval.body.gsub("GB2312", "UTF-8"))
    return parsed_result.xpath("//result").text == "success"
  end

  def self.get_order_index
    str = "0" * (4 - @@order_index.to_s.length) + @@order_index.to_s
    @@order_index += 1
    @@order_index = @@order_index % 10000
    str
  end

  # curl -X POST --data "UserNumber=1500009&InOrderNumber=IP1500009201405121447000000&OutOrderNumber=None&PhoneNumber=13488881477&Province=Auto&City=Auto&PhoneClass=Auto&PhoneMoney=10&SellPrice=None&StartTime=2014-5-12 14:49:00&TimeOut=300&RecordKey=CDCD7236A2B8CD11" http://www.esaipai.com/IF/EIFPHONE/IRechargeList_Phone_Test
  def charge_phone_test(phone_number, amount, code)
    time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    in_order_number = "IP#{@user_number}#{Time.now.strftime("%Y%m%d%H%M%S")}#{self.class.get_order_index}"
    sell_price = "None"
    timeout = 300
    key = Digest::MD5.hexdigest("#{@user_number}#{in_order_number}#{code}#{phone_number}AutoAutoAuto#{amount}#{sell_price}#{time}#{timeout}#{@sign}")[0..15].upcase
    params = {"UserNumber" => @user_number,
      "InOrderNumber" => in_order_number,
      "OutOrderNumber" => code,
      "PhoneNumber" => phone_number,
      "Province" => "Auto",
      "City" => "Auto",
      "PhoneClass" => "Auto",
      "PhoneMoney" => amount,
      "SellPrice" => sell_price,
      "StartTime" => time,
      "TimeOut" => timeout,
      "RecordKey" => key}
    retval = self.class.post("/IRechargeList_Phone_Test", {body: params})
    return retval
  end

  def charge_phone(phone_number, amount, code)
    time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    in_order_number = "IP#{@user_number}#{Time.now.strftime("%Y%m%d%H%M%S")}#{self.class.get_order_index}"
    sell_price = "None"
    timeout = 300
    key = Digest::MD5.hexdigest("#{@user_number}#{in_order_number}#{code}#{phone_number}AutoAutoAuto#{amount}#{sell_price}#{time}#{timeout}#{@sign}")[0..15].upcase
    params = {"UserNumber" => @user_number,
      "InOrderNumber" => in_order_number,
      "OutOrderNumber" => code,
      "PhoneNumber" => phone_number,
      "Province" => "Auto",
      "City" => "Auto",
      "PhoneClass" => "Auto",
      "PhoneMoney" => amount,
      "SellPrice" => sell_price,
      "StartTime" => time,
      "TimeOut" => timeout,
      "RecordKey" => key}
    retval = self.class.post("/IRechargeList_Phone", {body: params})
    parsed_result = Nokogiri::XML(retval.body.gsub("GB2312", "UTF-8"))
    success = parsed_result.xpath("//result").text == "success"
    return in_order_number if success
  end

  def check_result_test(in_order_number, code)
    retval = nil
    key = Digest::MD5.hexdigest("1500009#{in_order_number}#{code}Ptestkey")[0..15].upcase
    params = {"UserNumber" => "1500009",
      "InOrderNumber" => in_order_number,
      "OutOrderNumber" => code,
      "QueryType" => "P",
      "RecordKey" => key}
    with_different_base_uri("http://www.esaipai.com/IF/EIFQUERY/") do
      begin
        retval = self.class.post("/IRechargeResult_Test", {body: params})
      rescue Exception => err
        Rails.logger.error err
      end
    end
    parsed_result = Nokogiri::XML(retval.body.gsub("GB2312", "UTF-8"))
    success = parsed_result.xpath("//result").text == "success"
    return parsed_result.xpath("//payResult").text.to_i if success
  end

  def check_result(in_order_number, code)
    retval = nil
    key = Digest::MD5.hexdigest("#{@user_number}#{in_order_number}#{code}P#{@sign}")[0..15].upcase
    params = {"UserNumber" => @user_number,
      "InOrderNumber" => in_order_number,
      "OutOrderNumber" => code,
      "QueryType" => "P",
      "RecordKey" => key}
    with_different_base_uri("http://www.esaipai.com/IF/EIFQUERY/") do
      begin
        retval = self.class.post("/IRechargeResult", {body: params})
      rescue Exception => err
        Rails.logger.error err
      end
    end
    parsed_result = Nokogiri::XML(retval.body.gsub("GB2312", "UTF-8"))
    success = parsed_result.xpath("//result").text == "success"
    return parsed_result.xpath("//payResult").text.to_i if success
  end

  def self.callback(in_order_number, result)
    order = Order.where(esai_order_id: in_order_number).first
    return if order.nil?
    if result.to_i == 4
      order.update_attributes(status: Order::SUCCESS, esai_status: Order::ESAI_SUCCESS)
      order.send_mobile_charge_success_message
    else
      order.update_attributes(esai_status: Order::ESAI_FAIL)
    end
  end
end
