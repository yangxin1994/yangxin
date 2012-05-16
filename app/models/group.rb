require 'error_enum'
class Group
  include Mongoid::Document
	field :owner_email, :type => Integer
	field :name, :type => String
	field :description, :type => String
	# array of members' emails
	field :members, :type => Array, default: []
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
	def self.get_groups(owner_email)
		return ErrorEnum::EMAIL_NOT_EXIST if User.find_by_email(owner_email) == nil
		groups_obj = []
		self.groups_of(owner_email).each do |group|
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
	def self.check_and_create_new(owner_email, name, description, members)
		# this owner already has a group with the same name
		return ErrorEnum::EMAIL_NOT_EXIST if User.find_by_email(owner_email) == nil
		group = Group.new(:owner_email => owner_email, :name => name, :description => description, :members =>  members)
		group.save
		return group.serialize
	end

	#*description*: update a group
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the group to be updated
	#* the group object to be updated
	#
	#*retval*:
	#* the updated group object
	#* ErrorEnum ::GROUP_NOT_EXIST : if cannot find the group
	#* ErrorEnum ::UNAUTHORIZED : if cannot find the group
	def self.update(owner_email, group_id, group_obj)
		group = find_by_id(group_id)
		return ErrorEnum::GROUP_NOT_EXIST if group == nil
		return ErrorEnum::UNAUTHORIZED if owner_email != group["owner_email"]
		group.update_attributes(:name => group_obj["name"], :description => group_obj["description"], :members => Marshal.load(Marshal.dump(group_obj["members"])))
		return group.serialize
	end

	#*description*: delete a group
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the group to be deleted
	#
	#*retval*:
	#* true if the group is deleted
	#* ErrorEnum ::GROUP_NOT_EXIST : if cannot find the group
	#* ErrorEnum ::UNAUTHORIZED : if cannot find the group
	def self.delete(owner_email, group_id)
		group = find_by_id(group_id)
		return ErrorEnum::GROUP_NOT_EXIST if group == nil
		return ErrorEnum::UNAUTHORIZED if owner_email != group["owner_email"]
		group.status = -1
		return group.save
	end

	#*description*: show a group
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the group to be shown
	#
	#*retval*:
	#* the group object
	#* ErrorEnum ::GROUP_NOT_EXIST : if cannot find the group
	#* ErrorEnum ::UNAUTHORIZED : if cannot find the group
	def self.show(owner_email, group_id)
		group = find_by_id(group_id)
		return ErrorEnum::GROUP_NOT_EXIST if group == nil
		return ErrorEnum::UNAUTHORIZED if owner_email != group["owner_email"]
		return group.serialize
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
		return group_obj
	end
end
