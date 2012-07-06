require 'error_enum'
class Group
  include Mongoid::Document
	field :name, :type => String
	field :description, :type => String
	# array of members' emails
	field :members, :type => Array, default: []

	belongs_to :user

	#*description*: find a group by its id. return nil if cannot find
	#
	#*params*:
	#* id of the group to be found
	#
	#*retval*:
	#* the group instance found, or nil if cannot find
	def self.find_by_id(group_id)
		group = Group.where(:_id => group_id).first
		return group
	end

	#*description*: create a new group, the parameter is a hash
	#
	#*params*:
	#* email of the user doing this operation
	#* name of the new group
	#* description of the new group
	#* members array of the new group
	#
	#*retval*:
	#* the group object
	#* ErrorEnum ::GROUP_NOT_EXIST : if cannot find the group
	def self.check_and_create_new(group)
		# this owner already has a group with the same name
		group_inst = Group.new(:name => group["name"], :description => group["description"])
		group["members"].each do |member|
			return ErrorEnum::ILLEGAL_EMAIL if Tool.email_illegal?(member["email"])
			group_inst.members << {"email" => member["email"], "mobile" => member["mobile"].to_s, "name" => member["name"].to_s, "is_exclusive" => !(member["is_exclusive"].to_s == "false")}
		end
		group_inst.save
		return group_inst
	end

	#*description*: update a group
	#
	#*params*:
	#* id of the group to be updated
	#* the group object to be updated
	#
	#*retval*:
	#* the updated group object
	#* ErrorEnum ::GROUP_NOT_EXIST : if cannot find the group
	#* ErrorEnum ::UNAUTHORIZED : if cannot find the group
	def update_group(group_obj)
		self.name = group_obj["name"]
		self.description = group_obj["description"]
		self.members = []
		group_obj["members"].each do |member|
			return ErrorEnum::ILLEGAL_EMAIL if Tool.email_illegal?(member["email"])
			self.members << {"email" => member["email"], "mobile" => member["mobile"].to_s, "name" => member["name"].to_s, "is_exclusive" => member["is_exclusive"] == false}
		end
		return self.save
	end
end
