# encoding: utf-8
require 'net/http'
require 'uri'
require 'csv'

module EmailViewRender

	@@path = "./app/views/user_mailer/"


	def self.render_email(email_name, opt={})
		file_path = @@path + "#{email_name}_email.html.erb"
		return -1 if !File.exist?(file_path)
		# read the content in the file
		content = IO.read(file_path)
		# substitute the variables
		content.gsub!(/<%=\s*[a-z0-9_.]+\s*%>/) do |match|
			match.delete!("<%=> ")
			var_names = match.split('.')
			var = opt[var_names[0].to_sym]
			if var_names.length > 1
				var_names[1..-1].each do |method_name|
					var = var.send(method_name)
				end
			end
			var
		end
		# handle the loop
		partition_result = [content]
		cur_partition_result = content.partition(/<%\*\s*[a-z0-9\s.\|]+\s*%>/)
		while cur_partition_result[-1] != ""
			partition_result.delete_at(-1)
			partition_result = [partition_result, cur_partition_result].flatten
			cur_partition_result = partition_result[-1].partition(/<%\*\s*[a-z0-9\s.\|]+\s*%>/)
		end
		if partition_result.length == 1
			return content
		end
		former = partition_result[0]
		latter = partition_result[-1]
		header = partition_result[1]
		tailer = partition_result[-2]
		middle = partition_result[2]

		header.delete!("<%*> ")
		loop_var_names = header.split('|')
		loop_array_name = loop_var_names[0]
		loop_var_name = loop_var_names[1]
		middle_content = ""
		opt[loop_array_name.to_sym].each do |var|
			opt[loop_var_name.to_sym] = var
			cur_middle = middle.gsub(/<%=\*\s*[a-z0-9_.]+\s*%>/) do |match|
				match.delete!("<%=*> ")
				var_names = match.split('.')
				var = opt[var_names[0].to_sym]
				if var_names.length > 1
					var_names[1..-1].each do |method_name|
						var = var.send(method_name)
					end
				end
				var
			end
			middle_content = middle_content + cur_middle
		end
		content = former + middle_content + latter
		content.delete!("\n")
		content.delete!("\t")
		return content
	end
end
