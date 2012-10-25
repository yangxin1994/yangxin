# encoding: utf-8
require 'csv'
class Address

	@@provinces = nil
	@@province_cities = nil
	@@city_towns = nil

	def self.generate_address_file
		csv_text = File.read('lib/list.csv')
		csv = CSV.parse(csv_text, :headers => false)
		province_code = 0
		city_code = 0
		county_code = 0
		CSV.open('lib/address_info.csv', 'wb') do |csv_export|
			csv.each do |row|
				return if row[3].nil?
				if !row[0].nil?
					# save province
					province_code = province_code + 1
					city_code = 0
					county_code = 0
					csv_export << [province_code << 12, row[0].strip, 0]
					#Address.create(:code => province_code << 12, :name => row[0].strip, :address_type => 0)
				end
				if !row[2].nil?
					# save city
					city_code = city_code + 1
					county_code = 0
					csv_export << [(province_code << 12) + (city_code << 6), row[2].strip, 1]
					#Address.create(:code => (province_code << 12) + (city_code << 6), :name => row[2].strip, :address_type => 1)
				end
				# save county
				county_code = county_code + 1
				csv_export << [(province_code << 12) + (city_code << 6) + (county_code), row[3].strip, 2]
				#Address.create(:code => (province_code << 12) + (city_code << 6) + (county_code), :name => row[3].strip, :address_type => 2)
			end
		end
	end


	def self.ensure_cache
		if !@@provinces

			# import data from csv file
			csv = CSV.parse(File.read("lib/address_info.csv"), 
				:headers => false)

			# init caches
			@@provinces = []
			@@province_cities = {}
			@@city_towns = {}

			@@all_cities = []

			# parse csv data
			csv.each do |row|
				# convert int values
				row[0] = row[0].to_i
				row[2] = row[2].to_i
				# setup cache
				case row[2]
				when 0
					@@provinces << row[0..1]
				when 1
					province_id = (row[0] >> 12 << 12)
					@@province_cities[province_id] = [] if !@@province_cities[province_id]
					@@province_cities[province_id] << row[0..1]
					@@all_cities << row[0..1]
				when 2
					city_id = (row[0] >> 6 << 6)
					@@city_towns[city_id] = [] if !@@city_towns[city_id]
					@@city_towns[city_id] << row[0..1]
				end
			end
		end
	end

	def self.find_provinces
		self.ensure_cache
		return @@provinces
	end

	def self.find_cities
		self.ensure_cache
		return @@all_cities
	end

	def self.find_cities_by_province(province_id)
		self.ensure_cache
		return @@province_cities[province_id]
	end

	def self.find_towns_by_city(city_id)
		self.ensure_cache
		return @@city_towns[city_id]
	end

	def self.find_address_code_by_ip(ip_address)
		return nil		#TODO: HACK for bug, remove this line ********************
		self.ensure_cache
		ip_info = IpInfo.find_by_ip(ip_address)
		# no province information in the ip info
		return -1 if ip_info.class != Postcode || ip_info.province.blank?
		target_province = nil
		@@provinces.each do |province|
			if province[1].gsub(/\s+/, "").include?(ip_info.province.gsub(/\s+/, ""))
				target_province = province[0]
			end
		end
		# the province cannot be found
		return -1 if target_province.nil?
		target_city = nil
		self.find_cities_by_province(target_province).each do |city|
			target_city = city[0] if city[1].gsub(/\s+/, "").include?(ip_info.city.gsub(/\s+/, ""))
		end
		# if city can be found, return city code, otherwise, return province code
		return (target_city.nil? ? target_province : target_city)
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
		Address.find_provinces.each do |province|
			province_hash[province[0]] = 0
		end
		return province_hash
	end

	def self.city_hash
		city_hash = {}
		Address.find_cities.each do |city|
			city_hash[city[0]] = 0
		end
		return city_hash
	end
end
