# encoding: utf-8
require 'httparty'
require 'securerandom'

class TaobaoApi
    include HTTParty
    # formal environment
    # base_uri 'http://gw.api.taobao.com/router/rest'
    # sandbox environment
    base_uri 'http://gw.api.tbsandbox.com/router/rest'

    APP_KEY = "21587576"
    APP_ID = "1400726"


    def self.grant_jifenbao(alipay_account, amount, auth_token)
        params = {}
        params["method"] = "alipay.point.order.add"
        params["timestamp"] = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        params["app_id"] = APP_ID
        params["sign_type"] = "RSA"
        params["user_symble"] = alipay_account
        params["user_symble_type"] = "ALIPAY_LOGON_ID"
        params["point_count"] = amount
        params["merchant_order_no"] = SecureRandom::uuid.split('-').join
        params["memo"] = "问卷吧集分宝发放"
        params["order_time"] = Time.now.strftime("%Y-%m-%d %H:%M:%S")

        params = Hash[params.sort]

        params_str = APP_KEY
        params.each do |k,v|
            params_str += "#{k}#{v}"
        end
        params_str += APP_KEY

        params["sign"] = Digest::MD5.hexdigest(params_str).upcase

        result = get('/alipay.point.order.add',
                :query => params)
        puts result.parsed_response
    end
end
