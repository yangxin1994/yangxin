# encoding: utf-8
class Address
	include Mongoid::Document
	field :code, :type => Integer
	field :name, :type => String
	field :address_type, :type => Integer

	scope :provinces, lambda { where(:address_type => 0) }
	scope :cities, lambda { where(:address_type => 1) }
	scope :counties, lambda { where(:address_type => 2) }

	def self.find_provinces
		return self.provinces.map { |province_address| [province_address.code, province_address.name] }
	end

	def self.find_cities_by_province(province_code)
		target_cities = []
		cities_addresses = self.cities.each do |city|
			target_cities << city if (city.code >> 12) == (province_code >> 12) && province_code == (province_code >> 12 << 12)
		end
		return target_cities.map { |city_address| [city_address.code, city_address.name] }
	end

	def self.find_counties_by_city(city_code)
		target_counties = []
		counties_addresses = self.counties.each do |county|
			target_counties << county if (county.code >> 6) == (city_code >> 6) && city_code == (city_code >> 6 << 6)
		end
		return target_counties.map { |county_address| [county_address.code, county_address.name] }
	end

	def self.find_address_code_by_ip(ip_address)
		ip_info = IpInfo.find_by_ip(ip_address)
		# the province cannot be found
		return -1 if ip_info.nil? || ip_info.province.blank?
		target_province = nil
		self.provinces.each do |province|
			target_province = province if province.name.gsub(/\s+/, "").include?(ip_info.province.gsub(/\s+/, ""))
			break
		end
		# the province cannot be found
		return -1 if target_province.nil?
		target_city = nil
		self.find_cities_by_province(target_province.code).each do |city|
			target_city = city if city.name.gsub(/\s+/, "").include?(ip_info.city.gsub(/\s+/, ""))
		end
		# if city can be found, return city code, otherwise, return province code
		return (target_city.nil? ? target_province.code : target_city.code)
	end

	def self.satisfy_region_code?(candidate_code, condition_code)
		candidate_code = candidate_code.to_i
		condition_code = condition_code.to_i
		if (condition_type >> 12 << 12) == condition_type
			condition_type = 0
		elsif (condition_type >> 6 << 6) == condition_type
			condition_type = 1
		else
			condition_type = 2
		end

		if condition_type == 0
			return (candidate_code >> 12) == (condition_code >> 12)
		elsif condition_type == 1
			return (candidate_code >> 6) == (condition_code >> 6)
		else
			return candidate_code == condition_code
		end
	end

	def self.province_hash
		province_hash = {}
		Address.provinces.each do |province|
			province_hash[province.code] = 0
		end
		return province_hash
	end

	def self.city_hash
		city_hash = {}
		Address.cities.each do |city|
			city_hash[city.code] = 0
		end
		return city_hash
	end
end
