# encoding: utf-8
require 'digest/md5'
class BaseClient
	include HTTParty
	base_uri Rails.application.config.ofcard_service_uri
	format :xml

	attr_accessor :uri_prefix
	
	def initialize(uri_prefix)
		@uri_prefix = uri_prefix
		@userid = "A830057"
		@userpws = Digest::MD5.hexdigest('oopsdata@2013')
		@version = "6.0"
		@mobile_card_id = "140101"
		@qq_card_id = "220612"
	end

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
