	require 'net/http'
	require 'uri'

module Tool

	def self.email_illegal?(email)
		!email.to_s.include?("@")
	end


	def self.send_post_request(uri, params, ssl = false)
		uri = URI.parse(uri)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = ssl
		request = Net::HTTP::Post.new(uri.request_uri)
		request.set_form_data(params)
		response = http.request(request)
		return response
	end

	def self.send_get_request(uri, ssl = false)
		uri = URI.parse(uri)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = ssl
		request = Net::HTTP::Get.new(uri.request_uri)
		response = http.request(request)
		return response
	end

	#
	# check_ip_mask("218.192.3.42", "218.192.*.*")
	def self.check_ip_mask(ip_address, ip_mask)
		return ErrorEnum::IP_FORMAT_ERROR if ip_address.to_s=~/^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$/
		return ErrorEnum::IP_FORMAT_ERROR if !ip_address.to_s.split('.').select{|sec| sec.to_i > 255 || sec.to_i < 0}.empty?
		return ip_address.match(ip_mask).to_s == ip_address
	end

	def self.check_choice_question_answer(answer, standard_answer, fuzzy)
		standard_answer.each do |standard_choice|
			return false if !answer.include?(standard_choice)
		end
		if fuzzy.to_s == "true"
			return true
		else
			return answer.length == standard_answer.length
		end
	end

	def self.check_text_question_answer(answer, standard_answer, fuzzy)
		return false if !standard_answer.include?(answer)
		return false if standard_answer != answer && !fuzzy
		return true
	end
end
