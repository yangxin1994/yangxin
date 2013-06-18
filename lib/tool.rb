# encoding: utf-8
require 'net/http'
require 'uri'
require 'csv'
require 'quill_common'

module Tool

	def self.email_illegal?(email)
		!email.to_s.include?("@")
	end


	def self.send_post_request(uri, params, ssl = false, username = nil, password = nil)
		uri = URI.parse(uri)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = ssl
		request = Net::HTTP::Post.new(uri.request_uri)
		request.set_form_data(params)
		if @username.nil?
			request.basic_auth(username, password)
		end
		response = http.request(request)
		return response
	end

	def self.send_get_request(uri, ssl = false, username = nil, password = nil)
		uri = URI.parse(uri)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = ssl
		request = Net::HTTP::Get.new(uri.request_uri)
		if !username.nil?
			request.basic_auth(username, password)
		end
		response = http.request(request)
		return response
	end

	def self.send_delete_request(uri, params, ssl = false, username = nil, password = nil)
		uri = URI.parse(uri)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = ssl
		request = Net::HTTP::Delete.new(uri.request_uri)
		request.set_form_data(params)
		if @username.nil?
			request.basic_auth(username, password)
		end
		response = http.request(request)
		return response	
	end

	#
	# check_ip_mask("218.192.3.42", "218.192.*.*")
	def self.check_ip_mask(ip_address, ip_mask)
		return ErrorEnum::IP_FORMAT_ERROR if ip_address.to_s=~/^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$/
		return ErrorEnum::IP_FORMAT_ERROR if !ip_address.to_s.split('.').select{|sec| sec.to_i > 255 || sec.to_i < 0}.empty?
		ip_address_ary = ip_address.split('.')
		ip_mask_ary = ip_address.split('.')
		ip_address_ary.each_with_index do |seg, index|
			return false if ip_mask_ary[index] != "*" && ip_mask_ary[index] != ip_address_ary[index]
		end
		return true
	end

	def self.check_choice_question_answer(question_id, answer, standard_answer, fuzzy)
		question = BasicQuestion.find_by_id(question_id)
		issue = question.issue if !question.nil?
		if issue && issue["max_choice"] == 1
			# for single choice question, check weather user's answer is included in the standard answer
			return standard_answer.include?(answer[0])
		else
			standard_answer.each do |standard_choice|
				return false if !answer.include?(standard_choice)
			end
			if fuzzy.to_s == "true"
				return true
			else
				return answer.length == standard_answer.length
			end
		end
	end

	def self.check_address_blank_question_answer(answer, standard_answer)
		answer_region_code = answer["address"].to_i
		QuillCommon::AddressUtility.check_region_answer(answer_region_code, standard_answer)
	end

	def self.check_text_question_answer(answer, standard_answer, fuzzy)
		return false if !standard_answer.include?(answer)
		return false if standard_answer != answer && !fuzzy
		return true
	end

	def self.convert_digit(number)
		numbers = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
		return numbers[number.to_i%10]
	end

	def convert_to_int(time_ary)
		seconds = []
		seconds[6] = 1					# second
		seconds[5] = seconds[6] * 60	# minute
		seconds[4] = seconds[5] * 60	# hour
		seconds[3] = seconds[4] * 24	# day
		seconds[2] = seconds[3] * 7		# week
		seconds[1] = seconds[3] * 30	# month
		result = 0
		1.upto(6) do |index|
			result = result + seconds[index] * time_ary[index]
		end
		return result
	end

	def self.rand_id
		return (rand * 10**16).floor
	end

	def self.calculate_segmentation_distribution(segmentation, data)
		segmentation ||= []
		distribution = Array.new(segmentation.length + 1) {0}
		data.each do |e|
			segmentation.each_with_index do |seg, index|
				if e <= seg
					distribution[index] += + 1
					break
				end
			end
			if segmentation[-1].nil? || e > segmentation[-1]
				distribution[segmentation.length] += 1
			end
		end
		return distribution
	end
end
