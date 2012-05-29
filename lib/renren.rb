  # -*- coding: utf-8 -*-
require 'uri'
require 'multi_json'
require 'net/http'
require 'digest'

module Renren
  class Base
    attr_accessor :params
    
    def initialize(access_token)
      @params = {}
      @params[:method] = "friends.get"
      @params[:call_id] = Time.now.to_i
      @params[:format] = 'json'
      @params[:v] = '1.0'
      @params[:access_token] = access_token
    end
    
    def call_method(opts = {:method => "users.getInfo"})
      MultiJson.decode(Net::HTTP.post_form(URI.parse('http://api.renren.com/restserver.do'), update_params(opts)).body)
    end
    
    private
      def update_params(opts)
        params = @params.merge(opts){|key, first, second| second}
        params[:sig] = Digest::MD5.hexdigest(params.map{|k,v| "#{k}=#{v}"}.sort.join + Config::API_SECRET)
        params
      end
  end
  
  module Config
    API_SECRET = OOPSDATA[RailsEnv.get_rails_env]["renren_secret_key"]    
  end
end
