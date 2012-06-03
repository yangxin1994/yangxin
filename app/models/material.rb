require 'error_enum'
require 'securerandom'

class Material
	include Mongoid::Document
	# 0 for image, 1 for video, 2 for audio
	field :owner_email, :type => String
	field :material_type, :type => Integer
	field :location, :type => String
	field :title, :type => String
	# 0 for normal, -1 for deleted
	field :status, :type => Integer ,default: 0
	field :created_at, :type => Integer, default: -> {Time.now.to_i}
	scope :materials_of, lambda { |owner_email| where(:owner_email => owner_email, :status => 0) }

	def self.find_by_id(material_id)
		material = Material.where(:_id => material_id, :status.gt => -1)[0]
		return material
	end

	def self.check_and_create_new(current_user_email, material_type, location, title)
		return ErrorEnum::EMAIL_NOT_EXIST if User.find_by_email(current_user_email).nil?
		return ErrorEnum::WRONG_MATERIAL_TYPE if ![1, 2, 4].include?(material_type)
		material = Material.new(:owner_email => current_user_email, :material_type => material_type, :location => location, :title => title)
		material.save
		return material.serialize
	end

	def self.get_object_list(current_user_email, material_type)
		return ErrorEnum::WRONG_MATERIAL_TYPE if !(1..7).to_a.include?(material_type)
		object_list = []
		Material.materials_of(current_user_email).each do |material|
			object_list << material.serialize if material.material_type & material_type > 0
		end
		return object_list
	end

	def self.get_object(current_user_email, material_id)
		material = Material.find_by_id(material_id)
		return ErrorEnum::MATERIAL_NOT_EXIST if material.nil?
		return ErrorEnum::UNAUTHORIZED if material.owner_email != current_user_email
		return material.serialize
	end

	def delete(current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return self.update_attributes(:status => -1)
	end

	def clear(current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return self.destroy
	end

	def update_title(current_user_email, title)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		self.update_attributes(:title => title)
		return self.serialize
	end

	#*description*: serialize current instance into a material object
	#
	#*params*
	#
	#*retval*:
	#* a material object
	def serialize
		material_obj = Hash.new
		material_obj["owner_email"] = self.owner_email
		material_obj["material_id"] = self._id.to_s
		material_obj["material_type"] = self.material_type
		material_obj["title"] = self.title
		material_obj["location"] = self.location
		return material_obj
	end
end
