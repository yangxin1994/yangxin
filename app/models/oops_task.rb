#encoding: utf-8
require 'error_enum'
#Corresponding to the User collection in database. Record the user information and activities related to the usage of OopsData system.
class OopsTask
	include Mongoid::Document
	include Mongoid::Timestamps
	set_database :oops_task_development
	
	field :task_type, :type => Integer
	# priority of the task, the tasks with high priority will be fetched from the table firstly
	field :priority, :type => Integer, default: 0
	# execution time, only the tasks whose execution time is smaller than the current time are fetched
	field :executed_at, :type => Integer, :default => Time.now.to_i
	# used for the periodic tasks, the next execution time is set the the current execution time plus the period
	field :period, :type => Integer, default: -1
	# status of the task, can be -1 (pending), 0 (waiting), 1 (doing), or 2 (finished)
	field :status, :type => Integer, default: 0

end
