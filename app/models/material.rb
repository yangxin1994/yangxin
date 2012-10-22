require 'error_enum'
require 'securerandom'

class Material
	include Mongoid::Document
	include Mongoid::Timestamps
	# 1 for image, 2 for video, 4 for audio
	field :material_type, :type => Integer
	field :title, :type => String
	field :value, :type => String
	field :picture_url, :type => String

	belongs_to :user

	default_scope ->(o = 'ASC'){ order_by("created_at", o) }

	def self.find_by_id(material_id)
		return Material.where(:_id => material_id).first
	end

	def self.check_and_create_new(current_user, material)
		return ErrorEnum::WRONG_MATERIAL_TYPE unless [1, 2, 4].include?(material["material_type"].to_i)
		material_inst = Material.new(:material_type => material["material_type"].to_i, 
			:value => material["value"], 
			:title => material["title"])
		material_inst.save
		current_user.materials << material_inst
		current_user.save
		return material_inst
	end

	def self.find_by_type(material_type)
		return [] if !(1..7).to_a.include?(material_type)
		materials = []
		Material.all.each do |material|
			materials << material if material.material_type & material_type > 0
		end
		return materials
	end

	def update_material(material)
		return self.update_attributes(:material_type => material["material_type"], 
			:value => material["value"],
			:title => material["title"])
	end
end
