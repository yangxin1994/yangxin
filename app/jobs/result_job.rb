#encoding: utf-8

module Jobs

	class ResultJob
		include Resque::Plugins::Status

		@queue = :result_job

		def self.answers(survey_id, filter_index, include_screened_answer)
			survey = Survey.find_by_id(survey_id)
			answers = include_screened_answer ? survey.answers.not_preview.finished_and_screened : survey.answers.not_preview.finished
			if filter_index == -1
				set_status({"find_answers_progress" => 1})
				return answers
			end
			filter_conditions = self.survey.filters[filter_index]["conditions"]
			filtered_answers = []
			answers_length = answers.length
			answers.each_with_index do |a, index|
				filtered_answers << a if a.satisfy_conditions(filter_conditions)
				set_status({"find_answers_progress" => (index + 1) * 1.0 / answers_length})
			end
			return filtered_answers	
		end

		def send_data(post_to)
      url = URI.parse('http://192.168.1.129:9292')
      begin
        Net::HTTP.start(url.host, url.port) do |http| 
          r = Net::HTTP::Post.new(post_to)
          a = Time.now
          r.set_form_data(yield)
          p Time.now - a
          http.read_timeout = 120
          p "===== 准备连接 ====="
          http.request(r)
        end
      rescue Errno::ECONNREFUSED
        p "连接失败"
      rescue Timeout::Error
        p "超时"
      ensure
        export_process[:post] = 100
        self.save
        p "连接结束"
      end
    end

	end
end
