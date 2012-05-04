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

	# find a group by the owner email and the group name
	def self.find_by_owner_email_and_name(owner_email, name)
		group = Group.where(:owner_email => group["owner_email"], :name => group["name"], :status => 0)[0]
		return group
	end

	# create a new group, the parameter is a hash
	def self.check_and_create_new(owner_email, name, description, members)
		# this owner already has a group with the same name
		return ErrorEnum::EXIST if find_by_owner_email_and_name(owner_email, name) != nil
		group = Group.new(:owner_email => owner_email, :name => name, :description => description, :members =>  members)
		group.save
		return group
	end

	# update a group
	def self.update(owner_email, name, new_name, description, members)
		group = find_by_owner_email_and_name(owner_email, name)
		return ErrorEnum::NOT_EXIST if group == nil
		group.update_attributes(:name => new_name, :description => description, :members =>  members)
		return group
	end

	# destroy a group
	def self.delete(owner_email, name)
		group = find_by_owner_email_and_name(owner_email, name)
		return ErrorEnum::NOT_EXIST if group == nil
		group.update_attributes(:status => -1)
		return 1
	end

	# show a group
	def self.show(owner_email, name)
		group = find_by_owner_email_and_name(owner_email, name)
		return ErrorEnum::NOT_EXIST if group == nil
		return group
	end

end
