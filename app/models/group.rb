require 'error_enum'
class Group
  include Mongoid::Document
	field :owner_email, :type => Integer
	field :name, :type => String
	field :description, :type => String
	# array of members' emails
	field :members, :type => Array, default: []
	field :sub_groups, :type => Array, default: []
# 0 not destroyed
# -1 destroyed
	field :status, :type => Integer, default: 0
	# obtain groups for one owner user
	scope :groups_of, lambda { |owner_email| where(:owner_email => owner_email, :status => 0) }

	attr_accessible :owner_email, :name, :description, :members

	#*description*: find a group by its id. return nil if cannot find
	#
	#*params*:
	#* id of the group to be found
	#
	#*retval*:
	#* the group instance found, or nil if cannot find
	def self.find_by_id(group_id)
		group = Group.where(:_id => group_id, :status => 0)[0]
		return group
	end

	#*description*: get groups of a user
	#
	#*params*:
	#* email of the user doing this operation
	#
	#*retval*:
	#* the groups object array
	#* ErrorEnum ::EMAIL_NOT_EXIST
	def self.get_groups(current_user_email)
		return ErrorEnum::EMAIL_NOT_EXIST if User.find_by_email(current_user_email).nil?
		groups_obj = []
		self.groups_of(current_user_email).each do |group|
			groups_obj << group.serialize
		end
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
	def self.check_and_create_new(current_user_email, name, description, members, sub_groups)
		# this owner already has a group with the same name
		return ErrorEnum::EMAIL_NOT_EXIST if User.find_by_email(current_user_email).nil?
		group = Group.new(:owner_email => current_user_email, :name => name, :description => description)

		members.each do |member|
#return ErrorEnum::ILLEGAL_EMAIL Tool.email_illegal?(member["email"])
			return ErrorEnum::ILLEGAL_EMAIL if Tool.email_illegal?(member["email"])
			group.members << {"email" => member["email"], "mobile" => member["mobile"].to_s, "name" => member["name"].to_s, "is_exclusive" => !(member["is_exclusive"].to_s == "false")}
		end

		sub_groups.each do |sub_group_id|
			return ErrorEnum::GROUP_NOT_EXIST if Group.find_by_id(sub_group_id).nil?
			return ErrorEnum::UNAUTHORIZED if Group.find_by_id(sub_group_id).owner_email != current_user_email
			group.sub_groups << sub_group_id
		end
		group.save
		return group.serialize
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
	def update_group(current_user_email, group_obj)
		return ErrorEnum::UNAUTHORIZED if current_user_email != self.owner_email
		self.name = group_obj["name"]
		self.description = group_obj["description"]
		self.members = []
		group_obj["members"].each do |member|
			return ErrorEnum::ILLEGAL_EMAIL if Tool.email_illegal?(member["email"])
			self.members << {"email" => member["email"], "mobile" => member["mobile"].to_s, "name" => member["name"].to_s, "is_exclusive" => member["is_exclusive"] == false}
		end
		self.sub_groups = []
		group_obj["sub_groups"].each do |sub_group_id|
			return ErrorEnum::GROUP_NOT_EXIST if Group.find_by_id(sub_group_id).nil?
			return ErrorEnum::UNAUTHORIZED if Group.find_by_id(sub_group_id).owner_email != current_user_email
			self.sub_groups << sub_group_id
		end
		self.save
		return self.serialize
	end

	#*description*: delete a group
	#
	#*params*:
	#* email of the user doing this operation
	#
	#*retval*:
	#* true if the group is deleted
	#* ErrorEnum ::UNAUTHORIZED : if cannot find the group
	def delete(current_user_email)
		return ErrorEnum::UNAUTHORIZED if current_user_email != self.owner_email
		# remove this group from another one if this is a sub-group
		Group.groups_of(current_user_email).each do |group|
			group.sub_groups.delete(self._id.to_s)
			group.save
		end
		self.status = -1
		return self.save
	end

	#*description*: show a group
	#
	#*params*:
	#* email of the user doing this operation
	#
	#*retval*:
	#* the group object
	#* ErrorEnum ::UNAUTHORIZED : if cannot find the group
	def show(current_user_email)
		return ErrorEnum::UNAUTHORIZED if current_user_email != self.owner_email
		return self.serialize
	end

	#*description*: serialize current instance into a group object
	#
	#*params*
	#
	#*retval*:
	#* a group object
	def serialize
		group_obj = Hash.new
		group_obj["group_id"] = self._id.to_s
		group_obj["owner_email"] = self.owner_email
		group_obj["name"] = self.name
		group_obj["description"] = self.description
		group_obj["members"] = Marshal.load(Marshal.dump(self.members))
		group_obj["sub_groups"] = Marshal.load(Marshal.dump(self.sub_groups))
		return group_obj
	end
end
