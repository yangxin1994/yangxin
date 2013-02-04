# encoding: utf-8
require 'csv'
class Address

	@@all_address = nil
	@@provinces = nil
	@@province_cities = nil
	@@city_towns = nil

	@@all_cities = nil
	@@all_counties = nil

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
				end
				if !row[2].nil?
					# save city
					city_code = city_code + 1
					county_code = 0
					csv_export << [(province_code << 12) + (city_code << 6), row[2].strip, 1]
				end
				# save county
				county_code = county_code + 1
				csv_export << [(province_code << 12) + (city_code << 6) + (county_code), row[3].strip, 2]
			end
		end
	end

end
