require 'error_enum'
require 'securerandom'

class Material
	include Mongoid::Document
	# 1 for image, 2 for video, 4 for audio
	#field :owner_email, :type => String
	field :material_type, :type => Integer
	#field :location, :type => String
	field :title, :type => String
	#field :created_at, :type => Integer, default: -> {Time.now.to_i}

	mount_uploader :material, MaterialUploader
	belongs_to :materials, :polymorphic => true
	#belongs_to :userma

	#before_save :set_attachment_attributes


	def self.check_and_create_new(material)
		return ErrorEnum::WRONG_MATERIAL_TYPE if ![1, 2, 4].include?(material["material_type"].to_i)
		material_inst = Material.new(:material_type => material["material_type"].to_i, :location => material["location"], :title => material["title"])
		material_inst.save
		return material_inst
	end

	def self.find_by_type(material_type)
		return [] if !(1..7).to_a.include?(material_type)
		materials = []
		Material.materials_of(current_user.email).each do |material|
			materials << material if material.material_type & material_type > 0
		end
		return materials
	end

	def update_title(title)
		return self.update_attributes(:title => title)
	end

	protected

	def set_attachment_attributes
		if material.present? && material_changed?
			self.content_type = material.file.content_type
			self.file_size = material.file.size
			self.file_name = material.file.original_filename
		end
	end
end
