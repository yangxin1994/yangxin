class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :task_type, :type => String
  field :progress, :type => Hash, default: {}
  # status of the task, can be -1 (pending), 0 (waiting), 1 (doing), 2 (finished) or 3 (error)
  field :status, :type => Integer, default: 1

  def self.set_progress(task_id, progress_item, progress_value)
    task = Task.find_by_id(task_id)
    return false if task.nil?
    task.progress[progress_item.to_s] = progress_value
    return task.save
  end
end
