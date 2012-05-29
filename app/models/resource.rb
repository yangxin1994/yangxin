require 'error_enum'
require 'securerandom'

class Resource
	include Mongoid::Document
	# 0 for image, 1 for video, 2 for audio
	field :owner_email, :type => String
	field :resource_type, :type => Integer
	field :location, :type => String
	field :title, :type => String
	# 0 for normal, -1 for deleted
	field :status, :type => Integer ,default: 0
	field :created_at, :type => Integer, default: -> {Time.now.to_i}
	scope :resources_of, lambda { |owner_email| where(:owner_email => owner_email, :status => 0) }

	def self.find_by_id(resource_id, current_user_email)
		resource = Resource.where(:_id => resource_id, :status.gt => -1)[0]
		return ErrorEnum::UNAUTHORIZED if resource.owner_email != current_user_email
		return resource
	end

	def self.check_and_create_new(owner_email, resource_type, location, title)
		return ErrorEnum::EMAIL_NOT_EXIST if User.find_by_email(owner_email).nil?
		return ErrorEnum::WRONG_RESOURCE_TYPE if ![1, 2, 4].include?(resource_type)
		resource = Resource.new(:owner_email => owner_email, :resource_type => resource_type, :location => location, :title => title)
		resource.save
		return resource.serialize
	end

	def self.get_object_list(current_user_email, resource_type)
		return ErrorEnum::WRONG_RESOURCE_TYPE if !(1..7).to_a.include?(resource_type)
		object_list = []
		Resource.all.each do |resource|
			object_list << resource.serialize if resource.resource_type & resource_type > 0
		end
		return object_list
	end

	def self.get_object(current_user_email, resource_id)
		resource = Resource.find_by_id(resource_id)
		return ErrorEnum::RESOURCE_NOT_EXIST if resource.nil?
		return ErrorEnum::UNAUTHORIZED if resource.owner_email != current_user_email
		return resource.serialize
	end

	def delete(current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return self.update_attributes(:status => -1)
	end

	def clear(current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return self.destroy
	end

	def update_title(title, current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return self.update_attributes(:title => title)
	end

	#*description*: serialize current instance into a resource object
	#
	#*params*
	#
	#*retval*:
	#* a resource object
	def serialize
		resource_obj = Hash.new
		resource_obj["owner_email"] = self.owner_email
		resource_obj["resource_id"] = self._id.to_s
		resource_obj["resource_type"] = self.resource_type
		resource_obj["title"] = self.title
		resource_obj["location"] = self.location
		return resource_obj
	end
end
