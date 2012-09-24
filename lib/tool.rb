# encoding: utf-8
require 'net/http'
require 'uri'
require 'csv'

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

	def self.import_address
		Address.all.each do |e|
			e.destroy
		end
		csv_text = File.read('list.csv')
		csv = CSV.parse(csv_text, :headers => false)
		province_code = 0
		city_code = 0
		county_code = 0
		csv.each do |row|
			return if row[3].nil?
			if !row[0].nil?
				# save province
				province_code = province_code + 1
				city_code = 0
				county_code = 0
				Address.create(:code => province_code << 12, :name => row[0].strip, :address_type => 0)
			end
			if !row[2].nil?
				# save city
				city_code = city_code + 1
				county_code = 0
				Address.create(:code => (province_code << 12) + (city_code << 6), :name => row[2].strip, :address_type => 1)
			end
			# save county
			county_code = county_code + 1
			Address.create(:code => (province_code << 12) + (city_code << 6) + (county_code), :name => row[3].strip, :address_type => 2)
		end
	end
end
