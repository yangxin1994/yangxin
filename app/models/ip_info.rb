# coding: utf-8

require 'iconv'

class IpInfo
	include Mongoid::Document

	field :ip, :type => String, :default => ""

	belongs_to :postcode

	#--
	# instance methods
	#++

	#--
	# class methods
	#++
	
	class << self

		#
		#*description*: verify ip with regular expression
		#*params*:
		#* ip_address
		#
		#*retval*:
		# true or ErrorEnum::IP_FORMAT_ERROR
		def verify_ip(ip_address)
			return ErrorEnum::IP_FORMAT_ERROR if !ip_address.to_s=~/^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$/
			return ErrorEnum::IP_FORMAT_ERROR if !ip_address.to_s.split('.').select{|sec| sec.to_i > 255 || sec.to_i < 0}.empty?
			return true
		end

		#*description*: get ip info from sina api by ip address
		#*params*:
		#* ip_address
		#
		#*retval*:
		# json data of one ip info , or ErrorEnum::IP_REQUEST_SINA_ERROR
		def get_ip_info_from_sina_api(ip_address)
			retval = Tool.send_get_request("http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=js&ip="+ip_address.to_s)

			retval = retval.body.to_s.match(/{.*}/).to_s

			if retval.strip != "" then
				json_data = JSON.parse(retval)
				
				return json_data if json_data["ret"].to_i == 1
			end

			return ErrorEnum::IP_REQUEST_SINA_ERROR
		end

		#*description*: get postcode from baidu by city name
		#*params*:
		#* city_name
		#
		#*retval*:
		# string of postcode , or ""(empty string)
		def get_postcode_from_baidu(city_name)
			
			iconv_str = Iconv.iconv("gb2312","utf-8",city_name).to_s
			code_arr = iconv_str.split("\\x")
			code_arr = code_arr[1, code_arr.count-1]
			code_arr[code_arr.count-1]= code_arr[code_arr.count-1].sub(/"\]/,"")

			wd_str =""
			code_arr.each{ |code|
				code.sub!(/{/,"").sub!(/}/,"")
				code=code.insert(0,"%").insert(3,"%")
				wd_str+=code
			}

			#puts code_arr.to_s
			puts wd_str

			retval = Tool.send_get_request("http://opendata.baidu.com/post/s?wd=#{wd_str}&rn=20")
			#puts retval.body.to_s

			retval = retval.body.to_s.match(/<a data-type=1.*<!-- baidu-tc end -->/).to_s.match(/\d{6}/).to_s
			puts retval

			retval = retval=="" ? ErrorEnum::POSTCODE_REQUEST_BAIDU_ERROR : retval
			return retval
		rescue
			return ErrorEnum::POSTCODE_REQUEST_BAIDU_ERROR
		end

		#*description*: find ip info from ip_address
		#*params*:
		#* ip_address
		#
		#*retval*:
		# Postcode object, or ErrorEnum
		def find_by_ip(ip_address)

			#verify ip_address
			retval = verify_ip(ip_address)
			return retval if retval != true

			#check that db contains this ip or not.
			retval = IpInfo.where(ip: ip_address.strip).first

			return retval.postcode if !retval.nil?

			# if db does not contains this ip info
			# get ip info from sina api
			information = get_ip_info_from_sina_api(ip_address)
			return information if !information.instance_of?(Hash)

			#new ip record
			ip = IpInfo.new(:ip => ip_address.strip)

			postcode = get_postcode(information)
			return postcode if postcode.to_i <= 0

			# now, 
			# the postcode record must be existed.
			ip.postcode = postcode

			return ip.postcode if ip.save
			return ErrorEnum::UNKNOWN_ERROR
		end

		#*description*: get postcode from db or net
		#*params*:
		#* ip_address
		#
		#*retval*:
		# Postcode object, or ErrorEnum
		def get_postcode(information)
			if information["city"] then
				#find in Postcode by city
				pc = Postcode.where(city: information["city"]).first

				#if exist, return
				return pc if !pc.nil?

				# if can not find record in Postcode,
				# create one 
				p_code = get_postcode_from_baidu(information["city"].to_s) 
				return p_code if p_code.to_i <= 0

				information["postcode"] = p_code
				information.select!{|k,v| %w(province city postcode).include?(k.to_s)}

				# create a postcode record
				postcode = Postcode.new(information)
				return ErrorEnum::UNKNOWN_ERROR if !postcode.save
				return postcode
			else
				return ErrorEnum::UNKNOWN_ERROR
			end		
		end

	end

end