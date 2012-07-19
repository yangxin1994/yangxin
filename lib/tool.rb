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

		puts response.body

		return response
	end

	def self.check_ip_mask(ip_address, ip_mask)
	end

	def self.get_region_by_ip(ip)
	end

	def self.check_question_answer(answer, standard_answer, fuzzy)
		standard_answer.each do |standard_choice|
			return false if !answer.include?(standard_choice)
		end
		if fuzzy.to_s == "true"
			return true
		else
			return answer.length == standaard_answer.length
		end
	end
end
