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

end
