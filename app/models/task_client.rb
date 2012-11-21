#encoding: utf-8
#Corresponding to the User collection in database. Record the user information and activities related to the usage of OopsData system.
class TaskClient
	include HTTParty
	base_uri Rails.application.config.task_web_service_uri
	format :json

	def self.create_task(task_obj)
		# determine the priority based on the task type
		priority = 0
		case task_obj[:task_type]
		when :EmailJob
			priority = 1
		when :ResultJob
			priority = 1
		end
		task_obj.merge!({priority: priority})
		
		# send request to the oops-task server
		response = self.class.post('/tasks.json', {:body => {:task => task_obj}})
		result = response.parsed_response
		if result && result["success"]
			return result["value"]
		else
			return ErrorEnum::TASK_CREATION_FAILED
		end
	end

	def self.set_progress(task_id, progress_item, progress_value)
		# put to tasks
	end
end
